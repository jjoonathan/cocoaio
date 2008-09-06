/**
 *  @file CIOUSBDevice.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/20/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOService.h"
#import <IOKit/usb/USB.h>
#import <IOKit/usb/IOUSBLib.h>

@interface CIOUSBDevice : CIOService {
	IOUSBDeviceInterface** mDeviceInterface;
	IOUSBDeviceDescriptor mDescriptor;
}
//Internal
- (BOOL)createDeviceInterface:(NSError**)err; //YES on success
- (void)destroyDeviceInterface; ///@raises on error
- (BOOL)open:(NSError**)error;
- (void)close; ///@raises on error

//Info (all these will raise on an error)
- (double)powerAvailable; //In mA
- (UInt8)usbClass;
- (UInt8)productID;
- (UInt8)deviceProtocol;
- (UInt16)releaseNumber;
- (UInt8)speed;
- (NSString*)speedName; //@"Low", @"Full", or @"High"
- (UInt8)usbSubClass;
- (UInt16)vendor;
- (UInt32)locationID;
- (NSArray*)configurations; ///<Use -configurations and -setConfiguration:error: for easiest operation. The others are just slightly more efficient.
- (UInt8)configurationCount;
- (UInt8)currentConfigurationNumber;
- (IOUSBConfigurationDescriptorPtr)rawConfigurationAtIndex:(UInt8)conf;
- (NSDictionary*)configurationAtIndex:(UInt8)conf;

//Control
- (BOOL)reset:(NSError**)err;
- (BOOL)setConfiguration:(NSDictionary*)conf error:(NSError**)err;
- (BOOL)setConfigurationNumber:(UInt8)conf error:(NSError**)err;
@end
