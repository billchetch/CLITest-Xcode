//
//  ScanTest.m
//  CLITest
//
//  Created by Bill Thorgerson on 17/03/26.
//

#import "ScanTest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ScanTest ()
// Private property (makes publicData internally readwrite)
@property (nonatomic, strong, readwrite) NSString *peripheralToFind;
@property (nonatomic, strong, readwrite) NSString *serviceDescription;
@property (nonatomic, strong, readwrite) NSString *characteristicDescription;
@property (nonatomic, readwrite) BOOL isReady;

@end

@implementation ScanTest

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
        NSLog(@"Bluetooth is powered on AND authorized! Scanning for %@...",  self.peripheralToFind);
    } else {
        NSLog(@"Bluetooth is not powered on or authorized.");
    }
}

// Delegate method: Handle discovery
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered: %@, RSSI: %@", peripheral.name, RSSI);
    
    BOOL found = false;
    if (peripheral.name && [peripheral.name caseInsensitiveCompare:self.peripheralToFind] == NSOrderedSame) {
        [self stopScanning];
        found = true;
        self.peripheral = peripheral;
        
        if(self.discovered){
            self.discovered(self, found, nil);
        }
        
        NSLog(@"Connecting %@...", self.peripheral.name);
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
    
    NSLog(@"Failed to connect to peripheral: %@. Error: %@", peripheral.name, error.localizedDescription);
    // You may attempt to reconnect or handle the error appropriately
    
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
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        if(self.servicesDiscovered){
            self.servicesDiscovered(self, false, error);
        }
        return;
    }
    
    
    NSLog(@"Discovered %@ services", peripheral.name);
    
    BOOL found = false;
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        
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
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        self.isReady = false;
        if(self.ready){
            self.ready(self, false, error);
        }
        return;
    }
    
    
    BOOL found = false;
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic: %@", characteristic.UUID);
        
        if(characteristic.UUID.description && [self.characteristicDescription caseInsensitiveCompare:characteristic.UUID.description] == NSOrderedSame){
            NSLog(@"Found characterstic!");
            found = true;
            self.characteristic = characteristic;
            break;
        }
    }
    
    self.isReady = found;
    if(self.ready){
        self.ready(self, found, error);
    }
    
}


NS_ASSUME_NONNULL_BEGIN

NS_ASSUME_NONNULL_END
@end


