/**
 *  @file CIOService.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/18/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIORegistryEntry.h"
#ifdef __cplusplus
	#import <vector>
	typedef struct{io_object_t obj; NSString* type;} CIOServiceNotification;
	typedef std::vector<CIOServiceNotification> CIOServiceNotificationVec;
#endif

extern NSString* CIOServiceChangedNotification;
extern NSString* CIOGeneral;  /* Always @"General" */
extern NSString* CIOBusyness; /* Always @"Busyness" */
extern NSString* CIOPower;    /* Always @"Power" */
extern NSString* CIOPriority; /* Always @"Priority" */
extern NSString* CIOPlatform; /* Always @"Platform" */


@interface CIOService : CIORegistryEntry {
#ifdef __cplusplus
	CIOServiceNotificationVec* mNotifications;
#endif
	io_connect_t mConnection;
}
- (void)startWatching:(NSString*)notificationType; ///<Start watching for notifications on this object of notificationType. Use [CIO() checkForNotificationsOnThisThread] if you want to check for notificaitons on any but the current thread.
- (unsigned)busyness; ///<Busy state count
- (BOOL)waitForSeconds:(unsigned int)secs nanosecs:(int)nsecs; ///<Waits for the receiver to become unbusy (business==0) or the specified time to elapse
- (kern_return_t)scanForNewDevices; ///<Only used on old busses, like SCSI. Returns the code returned in the kernel.
- (io_connect_t)connectionOfType:(long)type; //For getting a raw connection, maybe to a custom 
- (void)closeConnection;
@end
