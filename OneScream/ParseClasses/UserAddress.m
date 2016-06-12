//
//  UserAddress.m
//  OneScream
//
//  Created by sohail khan on 22/03/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import "UserAddress.h"


@interface UserAddress ()<PFSubclassing>
{

}
@end
@implementation UserAddress
@dynamic addressType,state,city,streetAddress1,streetAddress2,postal,businessName;
+(NSString*)parseClassName{
    return @"UserAddress";
}

@end
