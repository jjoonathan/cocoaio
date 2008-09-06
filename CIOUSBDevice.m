/**
 *  @file CIOUSBDevice.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/20/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOUSBDevice.h"
#import <IOKit/IOCFPlugin.h>


@implementation CIOUSBDevice
#define mDevice() (io_service_t)mRawObject

/************************************/ #pragma mark C&D /************************************/
- (void)dealloc {
	[self close];
	[super dealloc];
}

/************************************/ #pragma mark Internal /************************************/
- (BOOL)createDeviceInterface:(NSError**)err {
	if (mDeviceInterface) return YES;
	
	SInt32 score;
	IOCFPlugInInterface** plugin_interface;
	kern_return_t kr = IOCreatePlugInInterfaceForService(mDevice(), kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugin_interface, &score);
	if (kr!=kIOReturnSuccess) {
		if (err) *err=[NSError errorWithDomain:NSMachErrorDomain code:kr userInfo:[NSDictionary dictionaryWithObject:self forKey:@"device"]];
		return NO;
	}
	
	HRESULT result;
	result = (*plugin_interface)->QueryInterface(plugin_interface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID*)&mDeviceInterface);
	
	(*plugin_interface)->Release(plugin_interface);
	
	if (result||!mDeviceInterface) {
		if (err) *err=[NSError errorWithDomain:NSMachErrorDomain code:result userInfo:[NSDictionary dictionaryWithObject:self forKey:@"device"]];
		return NO;
	}
	
	return YES;
}

- (void)destroyDeviceInterface {
	if (!mDeviceInterface) return;
	(*mDeviceInterface)->Release(mDeviceInterface);
}

- (BOOL)open:(NSError**)error {
	NSError* e;
	BOOL cd = [self createDeviceInterface:&e];
	if (!cd) {
		if (error) *error=e;
		return NO;
	}
	IOReturn kr = (*mDeviceInterface)->USBDeviceOpen(mDeviceInterface);
	if (kr!=kIOReturnSuccess) {
		if (error) *error = [NSError errorWithDomain:NSMachErrorDomain code:kr userInfo:[NSDictionary dictionaryWithObject:self forKey:@"device"]];
		return NO;
	}
	return YES;
}

#define RAISE_ON_UNEXPECTED_FAILURE(ACTION) if (kr!=kIOReturnSuccess)\
	[NSException raise:NSInternalInconsistencyException format:@"Failed to " ACTION " the USB device %@", self];

- (void)close {
	if (!mDeviceInterface) return;
	//Implicit USBDeviceClose
	kern_return_t kr = (*mDeviceInterface)->Release(mDeviceInterface);
	RAISE_ON_UNEXPECTED_FAILURE(@"close")
	mDeviceInterface = NULL;
}



/************************************/ #pragma mark Info (all these will raise on an error) /************************************/
#define ASSURE_OPEN if (!mDeviceInterface) {\
	NSError* e; BOOL s = [self open:&e];\
	if (!s) {NSLog(@"Couldn't open device %@: %@", self, e); return 0;}\
}

- (double)powerAvailable { ASSURE_OPEN
	UInt32 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceBusPowerAvailable(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get available power");
	return (double)ret*2;
}

- (UInt8)usbClass { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceClass(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get USB class");
	return ret;
}

- (UInt8)productID { ASSURE_OPEN
	UInt16 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceProduct(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get product id");
	return ret;
}

- (UInt8)deviceProtocol { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceProtocol(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get device protocol");
	return ret;
}

- (UInt16)releaseNumber { ASSURE_OPEN
	UInt16 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceReleaseNumber(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get release number");
	return ret;
}

- (UInt8)speed { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceSpeed(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get speed");
	return ret;
}

- (NSString*)speedName {
	UInt8 s = [self speed];
	if (s==kUSBDeviceSpeedLow) return @"Low";
	if (s==kUSBDeviceSpeedFull) return @"Full";
	if (s==kUSBDeviceSpeedHigh) return @"High";
	return @"Unknown";
}

- (UInt8)usbSubClass { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceSubClass(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get subclass");
	return ret;
}

- (UInt16)vendor { ASSURE_OPEN
	UInt16 ret;
	IOReturn kr = (*mDeviceInterface)->GetDeviceVendor(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get vendor");
	return ret;
}

- (UInt32)locationID { ASSURE_OPEN
	UInt32 ret;
	IOReturn kr = (*mDeviceInterface)->GetLocationID(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get location ID");
	return ret;
}

- (UInt8)configurationCount { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetNumberOfConfigurations(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get number of configurations");
	return ret;
}

- (UInt8)currentConfigurationNumber { ASSURE_OPEN
	UInt8 ret;
	IOReturn kr = (*mDeviceInterface)->GetConfiguration(mDeviceInterface, &ret);
	RAISE_ON_UNEXPECTED_FAILURE(@"get current conf number");
	return ret;
}

- (IOUSBConfigurationDescriptorPtr)rawConfigurationAtIndex:(UInt8)conf { ASSURE_OPEN
	IOUSBConfigurationDescriptorPtr desc_ptr;
	IOReturn kr = (*mDeviceInterface)->GetConfigurationDescriptorPtr(mDeviceInterface, conf, &desc_ptr);
	RAISE_ON_UNEXPECTED_FAILURE(@"get conf");
	return desc_ptr;
}

- (NSDictionary*)configurationAtIndex:(UInt8)conf {
	IOUSBConfigurationDescriptorPtr desc_ptr = [self rawConfigurationAtIndex:conf];
	CFMutableDictionaryRef md = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	int v = desc_ptr->bLength; CFNumberRef r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"bLength", r); CFRelease(r);
	    v = desc_ptr->bDescriptorType;     r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"bDescriptorType", r); CFRelease(r);
	    v = desc_ptr->wTotalLength;        r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"wTotalLength", r); CFRelease(r);
	    v = desc_ptr->bNumInterfaces;      r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"bNumInterfaces", r); CFRelease(r);
	    v = desc_ptr->bConfigurationValue; r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"bConfigurationValue", r); CFRelease(r);
	    v = desc_ptr->iConfiguration;      r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"iConfiguration", r); CFRelease(r);
	    v = desc_ptr->bmAttributes;        r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"bmAttributes", r); CFRelease(r);
	    v = desc_ptr->MaxPower;            r = CFNumberCreate(NULL, kCFNumberIntType, &v); CFDictionaryAddValue(md, @"MaxPower", r); CFRelease(r);
	return [(id)md autorelease];
}

- (NSArray*)configurations {
	int cc = [self configurationCount];
	NSMutableArray* ret = [NSMutableArray array];
	int i; for (i=0; i<cc; i++) {
		[ret addObject:[self configurationAtIndex:i]];
	}
	return ret;
}

/************************************/ #pragma mark Control /************************************/
- (BOOL)reset:(NSError**)err { ASSURE_OPEN
	IOReturn r = (*mDeviceInterface)->ResetDevice(mDeviceInterface);
	if (r!=kIOReturnSuccess) {
		if (err) *err = [NSError errorWithDomain:NSMachErrorDomain code:r userInfo:[NSDictionary dictionaryWithObject:self forKey:@"device"]];
		return NO;
	}
	return YES;
}

- (BOOL)setConfiguration:(NSDictionary*)conf error:(NSError**)err {
	NSError* e; BOOL r = [self setConfigurationNumber:[[conf objectForKey:@"iConfiguration"] intValue] error:&e];
	if (!r) {
		if (err) *err = e;
		return NO;
	}
	return YES;
}

- (BOOL)setConfigurationNumber:(UInt8)conf error:(NSError**)err {  ASSURE_OPEN
	IOReturn kr = (*mDeviceInterface)->ResetDevice(mDeviceInterface);
	if (kr!=kIOReturnSuccess) {
		if (err) *err = [NSError errorWithDomain:NSMachErrorDomain code:kr userInfo:[NSDictionary dictionaryWithObject:self forKey:@"device"]];
		return NO;
	}
	return YES;
}


@end
