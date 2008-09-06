/**
 *  @file CIORegistryEntry.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import <IOKit/IOKitLib.h>
#import "CIOObject.h"

extern NSString* CIOServicePlane; /*Will always be @"Service"*/
extern NSString* CIOPowerPlane; /*Will always be @"Power"*/
extern NSString* CIODeviceTreePlane; /*Will always be @"Device"*/
extern NSString* CIOAudioPlane; /*Will always be @"Audio"*/
extern NSString* CIOFireWirePlane; /*Will always be @"FireWire"*/
extern NSString* CIOUSBPlane; /*Will always be @"USB"*/

@interface CIORegistryEntry : CIOObject {
}
- (NSArray*)children; ///<In default plane as defined by the global CIOObject
- (NSArray*)childrenInPlane:(NSString*)plane;
- (NSString*)name; ///<In default plane as defined by the global CIOObject
- (NSString*)nameInPlane:(NSString*)plane;
- (NSString*)path; ///<In default plane as defined by the global CIOObject
- (NSString*)pathInPlane:(NSString*)plane;
- (NSDictionary*)properties;
- (id)propertyNamed:(NSString*)name;
- (void)setValue:(id)v forPropertyNamed:(NSString*)pname;
@end
