//
//  CTCCBPeripheralManager.h
//
//
//  Created by Bill Thorgerson on 17/03/26.
//  Noodled again and again. Does this work?

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, CTCCBPeripheralDevice) {
    NOT_SPECIFIED = 0,
    JDY_23 = 1,
    JDY_31 = 2,
};

@interface CTCCBPeripheralManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

typedef void (^CTCCBPeripheralEvent)(CTCCBPeripheralManager* sender, BOOL success, NSError  * _Nullable error);
typedef void (^CTCCBIOEvent)(CTCCBPeripheralManager* sender, BOOL success, NSData * _Nullable data, NSError  * _Nullable error);

- (void)stopScanning;

- (void)scanForPeripheral:(NSString *)name withService:(NSString *)serviceDescription andCharacteristic:(NSString *)characteristicDescription;

- (void)scanForPeripheral:(CTCCBPeripheralDevice)device;

- (void)disconnectPeripheral;

- (int)write:(NSData *)data withResponse:(BOOL)respond;

- (int)write:(uint8_t*)data ofLength:(int)length withResponse:(BOOL)respond;

//@property (nonatomic, copy) void (^scanListener)(BOOL success);
@property (nonatomic, copy) CTCCBPeripheralEvent discovered;
@property (nonatomic, copy) CTCCBPeripheralEvent connected;
@property (nonatomic, copy) CTCCBPeripheralEvent disconnected;
@property (nonatomic, copy) CTCCBPeripheralEvent servicesDiscovered;
@property (nonatomic, copy) CTCCBPeripheralEvent ready;
@property (nonatomic, copy) CTCCBIOEvent dataReceived;



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
