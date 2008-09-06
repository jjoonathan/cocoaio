/**
 *  @file CocoaIO.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import <mach/port.h>
@class CIORegistryEntry;

#ifdef __cplusplus
#define CIO_EXTERN_C extern "C"
#else
#define CIO_EXTERN_C extern
#endif

CIO_EXTERN_C NSString* CIOMatchingNotification;

@interface CocoaIO : NSObject {
	mach_port_t mMasterPort;
	IONotificationPortRef mNotificationPort;
	void* mNotifications;
	//void* mNotificationSources; //Attachments to various run loops
	NSString* mDefaultPlane;
}
//Internal
+ (CocoaIO*)sharedInstance;
- (mach_port_t)masterPort;
- (IONotificationPortRef)notificationPort; //Automatically starts notifications on the current thread's run loop
- (void)checkForNotificationsOnThisThread; //Adds a task to the current thread's run loop to check for notifications. This is done automatically when notifyWhenMatches is called. You can add more run loops any time you want.

//Setting the "global plane"
- (NSString*)currentDefaultPlane;
- (void)setCurrentDefaultPlane:(NSString*)newPlane;

//Notifications
//action is one of @"Published", @"Terminated", @"FirstPublished", @"Matched", @"FirstMatched"
- (void)notifyWhenMatches:(NSDictionary*)match_dict are:(NSString*)action;
- (void)stopNotifiyWhenMatches:(NSDictionary*)match_dict are:(NSString*)action;

//Navigation around the registry
- (CIORegistryEntry*)registryRoot;
- (NSArray*)servicesForName:(NSString*)name; ///<Convenience
- (NSArray*)servicesForClass:(NSString*)name; ///<Convenience
- (NSArray*)servicesForBSDName:(NSString*)name; ///<Convenience
- (NSArray*)servicesForFWPath:(NSString*)name; ///<Convenience
- (NSArray*)servicesMatching:(NSDictionary*)matchDict; ///<You can get a matching dictionary from one of the C functions below
@end

	
@interface NSString (CocoaIO)
- (NSString*)ioSuperclass;
- (NSString*)ioBundleIdentifier;
@end


CIO_EXTERN_C NSMutableDictionary* CIOMatchClass(NSString* serviceClassName);
CIO_EXTERN_C NSMutableDictionary* CIOMatchName(NSString* serviceName);
CIO_EXTERN_C NSMutableDictionary* CIOMatchBSDName(NSString* bsdName);
CIO_EXTERN_C NSMutableDictionary* CIOMatchFWPath(NSString* firmwarePath);


CIO_EXTERN_C CocoaIO* CIO(); //A shortcut for the shared instance