//
//  UserAddress.h
//  OneScream
//
//  Created by sohail khan on 22/03/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import <Parse/Parse.h>

@interface UserAddress : PFObject
@property (nonatomic, strong) NSString *businessName;
@property (nonatomic, strong) NSString *streetAddress1;
@property (nonatomic, strong) NSString *streetAddress2;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *postal;
@property (nonatomic, strong) NSString *addressType;

@end
