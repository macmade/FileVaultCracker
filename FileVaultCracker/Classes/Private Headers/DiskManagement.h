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
 * @header      DiskManagement.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

@import Foundation;
@import DiskArbitration;

NS_ASSUME_NONNULL_BEGIN

@protocol DMManagerDelegate< NSObject >

@optional

- ( void )dmInterruptibilityChanged: ( BOOL )value;
- ( void )dmAsyncFinishedForDisk: ( DADiskRef )disk mainError: ( int )mainError detailError: ( int )detailError dictionary: ( NSDictionary * )dictionary;
- ( void )dmAsyncMessageForDisk: ( DADiskRef )disk string: ( NSString * )str dictionary: ( NSDictionary * )dict;
- ( void )dmAsyncProgressForDisk: ( DADiskRef )disk barberPole: ( BOOL )barberPole percent: ( float )percent;
- ( void )dmAsyncStartedForDisk: ( DADiskRef )disk;

@end

@protocol DMManagerClientDelegate< NSObject >

@end

@interface DMManager: NSObject

@property( atomic, readwrite, weak, nullable   ) id< DMManagerDelegate       > delegate;
@property( atomic, readwrite, weak, nullable   ) id< DMManagerClientDelegate > clientDelegate;
@property( atomic, readonly                    ) BOOL                          checkClientDelegate;
@property( atomic, readonly, nullable          ) NSArray                     * topLevelDisks;
@property( atomic, readonly, nullable          ) NSArray                     * disks;
@property( atomic, readwrite, assign, nullable ) DASessionRef                  defaultDASession;
@property( atomic, readwrite, strong, nullable ) NSString                    * language;

+ ( instancetype )sharedManager;
+ ( instancetype )sharedManagerForThread;

- ( BOOL )isCoreStoragePhysicalVolumeDisk: ( DADiskRef )disk error: ( NSError * __autoreleasing * )error;
- ( BOOL )isCoreStorageLogicalVolumeDisk: ( DADiskRef )disk error: ( NSError * __autoreleasing * )error;
- ( NSString * )diskUUIDForDisk: ( DADiskRef )disk error: ( NSError * __autoreleasing * )error;

@end

@interface DMCoreStorage: NSObject

- ( instancetype )initWithManager: ( DMManager * )manager;

- ( int )unlockLogicalVolume: ( NSString * )volumeUID options: ( NSDictionary * )options;
- ( int )doCallDaemonForCoreStorage: ( NSString * )selector inputDict: ( NSDictionary * )inputDict outputDict: ( NSDictionary  * _Nullable * _Nullable )outputDict checkDelegate: ( BOOL )checkDelegate sync: ( BOOL )sync;

- ( int )logicalVolumeGroups: ( NSArray< NSString * > * _Nullable * _Nullable )groups;
- ( int )logicalVolumeForDisk: ( DADiskRef )disk logicalVolume: ( NSString * _Nullable * _Nullable )logicalVolume;
- ( int )physicalVolumeAndLogicalVolumeGroupForDisk:( DADiskRef )disk physicalVolume: ( NSString * _Nullable * _Nullable )physicalVolume logicalVolumeGroup: ( NSString * _Nullable * _Nullable )logicalVolumeGroup;
- ( int )logicalVolumeGroupForLogicalVolume: ( NSString * )uuid logicalVolumeGroup:( NSString * _Nullable * _Nullable )group;
- ( int )copyDiskForLogicalVolume: ( NSString * )uuid disk: ( DADiskRef _Nullable * _Nullable )disk;
- ( int )isEncryptedDiskForLogicalVolume: ( NSString * )uuid encrypted:( BOOL * _Nullable )encrypted locked: ( BOOL * _Nullable )locked type: ( id _Nullable * _Nullable )type;

@end

NS_ASSUME_NONNULL_END
