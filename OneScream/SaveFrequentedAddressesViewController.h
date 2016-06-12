//
//  SaveFrequentedAddressesViewController.h
//  OneScream
//
//  Created by sohail khan on 20/03/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum AddressType
{
    HOME,
    WORK,
    FREQUENT
} AddressType;
@interface SaveFrequentedAddressesViewController : UIViewController
@property (nonatomic,assign)AddressType address_type;
@property (nonatomic,assign)BOOL isForUpdateAddress;
@end
