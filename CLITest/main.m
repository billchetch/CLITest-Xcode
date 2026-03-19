//
//  main.m
//  CLITest
//
//  Created by Bill Thorgerson on 15/03/26.
//

#import <Foundation/Foundation.h>
#import "DyLibTest/TestClass.h"
#import "ScanTest.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        ScanTest *scanTest = [[ScanTest alloc] init];
        scanTest.discovered = ^void(ScanTest* sender, BOOL found, NSError *error){
            if(found){
                NSLog(@"FOUND: %@", sender.peripheral.name);
            } else {
                NSLog(@"NOT FOUND!");
            }
        };
        
        scanTest.connected = ^void(ScanTest *sender, BOOL connected, NSError *error){
            NSLog(@"CONNECTED: %@", connected ? @"YES" : @"NO");
        };
        
        scanTest.disconnected = ^void(ScanTest *sender, BOOL success, NSError *error){
            NSLog(@"DISCONNECTED: %@", success ? @"YES" : @"NO");
        };
        
        scanTest.ready =^void(ScanTest* sender, BOOL ready, NSError *error){
            if(ready){
                NSLog(@"Ready for writing!");
                uint8_t bytes[] = {0x61, 0x62, 0x63};
                for(int i = 0; i < 10; i++){
                    [sender write: bytes ofLength: sizeof(bytes) withResponse: false];
                }
            } else {
                NSLog(@"Ready failed!");
            }
        };
        
        NSString *peripheralName = @"JDY-23";
        NSString *serviceDescription = @"FFE0";
        NSString *characteristicDescription = @"FFE1";
        
        //NSLog(@"Press ENTER to search for %@", peripheralName);
        //getchar();
        
        [scanTest scanForPeripheral:peripheralName withService:serviceDescription andCharacteristic:characteristicDescription];
        
        NSLog(@"Press ENTER to disconnect");
        getchar();
        [scanTest disconnectPeripheral];
        
        NSLog(@"Press ENTER to end");
        getchar();
        
    }
    return EXIT_SUCCESS;
}
