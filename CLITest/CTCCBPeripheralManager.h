//
//  ScanTest.h
//  CLITest
//
//  Created by Bill Thorgerson on 17/03/26.
//  Noodled again and again. Does this work?

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, CTCCBPeripheralDevice) {
    NOT_SPECIFIED = 0,
    JDY_23 = 1,
};

@interface CTCCBPeripheralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

typedef void (^PeripheralEvent)(CTCCBPeripheralManager* sender, BOOL success, NSError  * _Nullable error);

- (void)stopScanning;

- (void)scanForPeripheral:(NSString *)name withService:(NSString *)serviceDescription andCharacteristic:(NSString *)characteristicDescription;

- (void)scanForPeripheral:(CTCCBPeripheralDevice)device;


- (void)disconnectPeripheral;

- (int)write:(NSData *)data withResponse:(BOOL)respond;

- (int)write:(uint8_t*)data ofLength:(int)length withResponse:(BOOL)respond;

//@property (nonatomic, copy) void (^scanListener)(BOOL success);
@property (nonatomic, copy) PeripheralEvent discovered;
@property (nonatomic, copy) PeripheralEvent connected;
@property (nonatomic, copy) PeripheralEvent disconnected;
@property (nonatomic, copy) PeripheralEvent servicesDiscovered;
@property (nonatomic, copy) PeripheralEvent ready;


@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, readonly) NSString *peripheralToFind;
@property (nonatomic, readonly) NSString *serviceName;
@property (nonatomic, readonly) NSString *characteristicName;
@property (nonatomic, readonly) BOOL isReady;

//TODO: make these readonly
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBService *service;
@property (nonatomic, strong) CBCharacteristic *characteristic;


@end

NS_ASSUME_NONNULL_END
