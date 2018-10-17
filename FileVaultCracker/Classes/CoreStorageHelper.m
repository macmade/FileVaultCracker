/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

/*!
 * @file        CoreStorageHelper.m
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

@import DiskArbitration;

#import "CoreStorageHelper.h"
#import "DiskManagement.h"
#import <stdatomic.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreStorageHelper() < DMManagerDelegate, DMManagerClientDelegate >
{
    atomic_bool _unlocked;
}

@property( atomic, readwrite, strong ) DMManager     * manager;
@property( atomic, readwrite, strong ) DMCoreStorage * cs;

@end

NS_ASSUME_NONNULL_END

@implementation CoreStorageHelper

+ ( instancetype )sharedInstance
{
    static dispatch_once_t once;
    static id              instance = nil;
    
    dispatch_once
    (
        &once,
        ^( void )
        {
            instance = [ self new ];
        }
    );
    
    return instance;
}

- ( instancetype )init
{
    if( ( self = [ super init ] ) )
    {
        self.manager                = [ DMManager new ];
        self.manager.language       = @"English";
        self.manager.delegate       = self;
        self.manager.clientDelegate = self;
        self.cs                     = [ [ DMCoreStorage alloc ] initWithManager: self.manager ];
    }
    
    return self;
}

- ( BOOL )isValidLogicalVolumeUUID: ( NSString * )uuid
{
    return [ self.cs logicalVolumeGroupForLogicalVolume: uuid logicalVolumeGroup: NULL ] == 0;
}

- ( BOOL )isEncryptedLogicalVolumeUUID: ( NSString * )uuid
{
    BOOL encrypted;
    
    if( [ self.cs isEncryptedDiskForLogicalVolume: uuid encrypted: &encrypted locked: NULL type: NULL ] != 0 )
    {
        return NO;
    }
    
    return encrypted;
}

- ( BOOL )isLockedLogicalVolumeUUID: ( NSString * )uuid
{
    BOOL locked;
    
    if( [ self.cs isEncryptedDiskForLogicalVolume: uuid encrypted: NULL locked: &locked type: NULL ] != 0 )
    {
        return NO;
    }
    
    return locked;
}

- ( BOOL )unlockLogicalVolumeUUID: ( NSString * )volumeUUID withAKSUUID: ( NSString * )aksUUID
{
    NSMutableDictionary * options;
    
    atomic_store( &_unlocked, false );
    
    if( volumeUUID.length == 0 || aksUUID.length == 0 )
    {
        return NO;
    }
    
    options =
    @{
        @"lvuuid"  : volumeUUID,
        @"options" :
        @{
            @"AKSPassphraseUUID" : aksUUID
        }
    }
    .mutableCopy;
    
    [ self.cs unlockLogicalVolume: volumeUUID options: options[ @"options" ] ];
    
    CFRunLoopRun();
    
    return atomic_load( &_unlocked );
}

#pragma mark - DMManagerDelegate

- ( void )dmInterruptibilityChanged: ( BOOL )value
{
    ( void )value;
}

- ( void )dmAsyncFinishedForDisk: ( DADiskRef )disk mainError: ( int )mainError detailError: ( int )detailError dictionary: ( NSDictionary * )dictionary
{
    ( void )disk;
    ( void )mainError;
    ( void )detailError;
    ( void )dictionary;
    
    CFRunLoopStop( CFRunLoopGetCurrent() );
}

- ( void )dmAsyncMessageForDisk: ( DADiskRef )disk string: ( NSString * )str dictionary: ( NSDictionary * )dict
{
    NSNumber * n;
    
    ( void )disk;
    ( void )str;
    
    n = [ dict objectForKey: @"LVFUnlockSuccessful" ];
    
    if( n && [ n isKindOfClass: [ NSNumber class ] ] && [ n isEqual: @1 ] )
    {
        atomic_store( &_unlocked, true );
    }
}

- ( void )dmAsyncProgressForDisk: ( DADiskRef )disk barberPole: ( BOOL )barberPole percent: ( float )percent
{
    ( void )disk;
    ( void )barberPole;
    ( void )percent;
}

- ( void )dmAsyncStartedForDisk: ( DADiskRef )disk
{
    ( void )disk;
}

@end
