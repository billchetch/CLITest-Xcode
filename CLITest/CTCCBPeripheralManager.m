//
//  ScanTest.m
//  CLITest
//
//  Created by Bill Thorgerson on 17/03/26.
// And some more here

#import "CTCCBPeripheralManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCCBPeripheralManager ()
// Private property (makes publicData internally readwrite)
@property (nonatomic, strong, readwrite) NSString *peripheralToFind;
@property (nonatomic, strong, readwrite) NSString *serviceDescription;
@property (nonatomic, strong, readwrite) NSString *characteristicDescription;
@property (nonatomic, readwrite) BOOL isReady;

@end

@implementation CTCCBPeripheralManager

- (void)scanForPeripheral:(CTCCBPeripheralDevice)device{
    NSString* peripheralName;
    NSString* serviceDescription;
    NSString* characteristicDescription;
    
    switch(device){
        case JDY_23:
            peripheralName = @"JDY-23";
            serviceDescription = @"FFE0";
            characteristicDescription = @"FFE1";
            break;
            
        default:
            break;
    }
    
    if(peripheralName){
        [self scanForPeripheral:peripheralName withService: serviceDescription andCharacteristic:characteristicDescription];
    }
}

- (void)scanForPeripheral:(NSString *)name withService:(NSString *)serviceDescription andCharacteristic:(NSString *)characteristicDescription{
    self.peripheralToFind = name;
    self.serviceDescription = serviceDescription;
    self.characteristicDescription = characteristicDescription;
    
    if(self.centralManager && self.centralManager.isScanning){
        //Throw an exception?
    } else {
        dispatch_queue_t centralQueue = dispatch_queue_create("net.chetch.centralQueue", NULL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue options:nil];
    }
}

- (void)stopScanning {
    // 1. Initialize Central Manager
    //we don't need to holde a reference to this dispatch queue as it will persist until all tasks are complete
    if(self.centralManager){
        if(self.centralManager.isScanning){
            [self.centralManager stopScan];
        }
    } else {
        //throw an exception?
    }
}

- (void)disconnectPeripheral {
    if(self.centralManager && self.peripheral){
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
}

- (int)write:(NSData *)data withResponse:(BOOL)respond{
    if(self.isReady){
        CBCharacteristicWriteType cbType = respond ? CBCharacteristicWriteWithResponse : CBCharacteristicWriteWithoutResponse;
        [self.peripheral writeValue: data forCharacteristic: self.characteristic type: cbType];
        return (int)data.length;
    } else {
        return -1;
    }
}

- (int)write:(uint8_t*)bytes ofLength:(int)length withResponse:(BOOL)respond{
    NSData *data = [NSData dataWithBytes:bytes length:length];
    return [self write: data withResponse: respond];
}

//Delegate methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        // Scan for all devices (withServices: nil)
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    } else {
        //NSLog(@"Bluetooth is not powered on or authorized.");
        if(self.discovered){
            NSError *error = [NSError errorWithDomain:@"chetch" code:101 userInfo:nil];
            self.discovered(self, false, error);
        }
    }
}

// Delegate method: Handle discovery
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    BOOL found = false;
    if (peripheral.name && [peripheral.name caseInsensitiveCompare:self.peripheralToFind] == NSOrderedSame) {
        [self stopScanning];
        found = true;
        self.peripheral = peripheral;
        
        if(self.discovered){
            self.discovered(self, found, nil);
        }
        
        //NSLog(@"Connecting %@...", self.peripheral.name);
        [self.centralManager connectPeripheral:self.peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to %@", peripheral.name);
    if(peripheral != self.peripheral){
        //TODO: This would be very weird!  Exception time
        NSLog(@"Super weird!");
    } else {
        if(self.connected){
            self.connected(self, true, nil);
        }
        
        self.peripheral.delegate = self;
        [self.peripheral discoverServices:nil];
    }
}
NS_ASSUME_NONNULL_END

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if(self.connected){
        self.connected(self, false, error);
    }
}

- (void) centralManager:(CBCentralManager *) central didDisconnectPeripheral:(CBPeripheral *) peripheral error:(NSError *) error{
    if(self.disconnected){
        self.disconnected(self, true, error);
    }
}

//Peripheral delegate methods
- (void)peripheral:(CBPeripheral *) peripheral didDiscoverServices:(NSError *) error {
    if (error) {
        if(self.servicesDiscovered){
            self.servicesDiscovered(self, false, error);
        }
        return;
    }
    
    BOOL found = false;
    for (CBService *service in peripheral.services) {
        if(service.UUID.description && [self.serviceDescription caseInsensitiveCompare:service.UUID.description] == NSOrderedSame){
            NSLog(@"Found service!");
            found = true;
            self.service = service;
            // Discover characteristics for this service
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
    
    if(self.servicesDiscovered){
        self.servicesDiscovered(self, found, error);
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        self.isReady = false;
        if(self.ready){
            self.ready(self, false, error);
        }
        return;
    }
    
    
    BOOL found = false;
    for (CBCharacteristic *characteristic in service.characteristics) {
        if(characteristic.UUID.description && [self.characteristicDescription caseInsensitiveCompare:characteristic.UUID.description] == NSOrderedSame){
            found = true;
            self.characteristic = characteristic;
            CBCharacteristicProperties properties = self.characteristic.properties;
            if((properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify){
                //NOTE: this may not work first time, m
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            break;
        }
    }
    
    self.isReady = found;
    if(self.ready){
        self.ready(self, found, error);
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        //NSLog(@"Error reading characteristic: %@", [error localizedDescription]);
        if(self.dataReceived){
            NSError *error = [NSError errorWithDomain:@"chetch" code:102 userInfo:nil];
            self.dataReceived(self, false, nil, error);
        }
        return;
    }

    // Access the raw bytes
    NSData *data = characteristic.value;
    if(data.length && self.dataReceived){
        self.dataReceived(self, true, data, error);
    }
}
NS_ASSUME_NONNULL_BEGIN

NS_ASSUME_NONNULL_END
@end


