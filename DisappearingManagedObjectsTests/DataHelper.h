//
//  DataHelper.h
//  DisappearingManagedObjects
//
//  Created by Randall Becker on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>


@interface DataHelper : NSObject

@property (nonatomic, readonly, strong) NSManagedObjectContext *parentContext;
@property (nonatomic, readonly, strong) NSManagedObjectContext *childContext;
@property (nonatomic, readonly, strong) NSEntityDescription *employeeEntity;
@property (nonatomic, readonly, strong) NSEntityDescription *departmentEntity;

@end
