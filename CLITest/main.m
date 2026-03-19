//
//  main.m
//  CLITest
//
//  Created by Bill Thorgerson on 15/03/26.
//

#import <Foundation/Foundation.h>
#import "DyLibTest/TestClass.h"
#import "CTCCBPeripheralManager.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        CTCCBPeripheralManager *pmgr = [[CTCCBPeripheralManager alloc] init];
        pmgr.discovered = ^void(CTCCBPeripheralManager* sender, BOOL found, NSError *error){
            if(found){
                NSLog(@"FOUND: %@", sender.peripheral.name);
            } else {
                NSLog(@"NOT FOUND!");
            }
        };
        
        pmgr.connected = ^void(CTCCBPeripheralManager *sender, BOOL connected, NSError *error){
            NSLog(@"CONNECTED: %@", connected ? @"YES" : @"NO");
        };
        
        pmgr.disconnected = ^void(CTCCBPeripheralManager *sender, BOOL success, NSError *error){
            NSLog(@"DISCONNECTED: %@", success ? @"YES" : @"NO");
        };
        
        pmgr.ready =^void(CTCCBPeripheralManager *sender, BOOL ready, NSError *error){
            if(ready){
                NSLog(@"Ready for writing!");
                uint8_t bytes[] = {0x61, 0x62, 0x63};
                [sender write: bytes ofLength: sizeof(bytes) withResponse: false];
            } else {
                NSLog(@"Ready failed!");
            }
        };
        
        pmgr.dataReceived = ^void(CTCCBPeripheralManager *sender, BOOL success, NSData *data, NSError *error){
            if(success){
                NSLog(@"Data received! %d bytes", (int)data.length);
            } else {
                NSLog(@"Data receive failed!");
            }
        };
        
        CTCCBPeripheralDevice device = JDY_23;
        
        [pmgr scanForPeripheral:device];
        
        NSLog(@"Press ENTER to disconnect");
        getchar();
        [pmgr disconnectPeripheral];
        
        
    }
    return EXIT_SUCCESS;
}
