//
//  AppEventTracker.m
//  OneScream
//
//  Created by sohail khan on 24/02/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import "AppEventTracker.h"
#import "GoSquared/GoSquared.h"
#import <Parse/Parse.h>
@implementation AppEventTracker


+(void) initializeSDKKeys{
    [[GoSquared sharedTracker] setSiteToken:@"GSN-843918-U"];
    [[GoSquared sharedTracker] setApiKey:@"H6ESA3CBJN0M5FFT"];
}

+(void) onLogin{
    [[GoSquared sharedTracker] identify:[PFUser currentUser].email];
    
}
+(void) onSignOut{
    [[GoSquared sharedTracker] unidentify];
}
+(void) trackEvnetWithName:(NSString*)name withData:(NSDictionary *)dataDic{
    [[GoSquared sharedTracker] trackEvent:name withProperties:dataDic];
    
}
+(void)trackScreenWithName: (NSString *)name{
    [[GoSquared sharedTracker] trackScreen:name];
}
@end
