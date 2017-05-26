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

NS_ASSUME_NONNULL_BEGIN

@interface CoreStorageHelper() < DMManagerDelegate >
{
    DASessionRef _session;
    CFRunLoopRef _runLoop;
}

@property( atomic, readwrite, strong ) DMManager     * manager;
@property( atomic, readwrite, strong ) DMCoreStorage * cs;

@end

NS_ASSUME_NONNULL_END

@implementation CoreStorageHelper

- ( instancetype )init
{
    if( ( self = [ super init ] ) )
    {
        _session = DASessionCreate( NULL );
        _runLoop = CFRunLoopGetCurrent();
        
        CFRetain( _runLoop );
        DASessionScheduleWithRunLoop( _session, _runLoop, kCFRunLoopDefaultMode );
        
        self.manager                  = [ DMManager sharedManagerForThread ];
        self.manager.defaultDASession = _session;
        self.manager.language         = @"English";
        self.manager.delegate         = self;
        self.cs                       = [ [ DMCoreStorage alloc ] initWithManager: self.manager ];
    }
    
    return self;
}

- ( void )dealloc
{
    DASessionUnscheduleFromRunLoop( _session, _runLoop, kCFRunLoopDefaultMode );
    CFRelease( _session );
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

#pragma mark - DMManagerDelegate



@end
