//
//  AppEventTracker.h
//  OneScream
//
//  Created by sohail khan on 24/02/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppEventTracker : NSObject

+(void) initializeSDKKeys;
+(void) onLogin;
+(void) onSignOut;
+(void) trackEvnetWithName:(NSString*)name withData:(NSDictionary *)dataDic;

+(void)trackScreenWithName: (NSString *)name;
@end
