//
//  DataHelper.m
//  DisappearingManagedObjects
//
//  Created by Randall Becker on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataHelper.h"

@interface DataHelper ()

@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;

@end


@implementation DataHelper

@synthesize parentContext = _parentContext;
@synthesize childContext = _childContext;
@synthesize employeeEntity = _employeeEntity;
@synthesize departmentEntity = _departmentEntity;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;

- (NSEntityDescription *)departmentEntity
{
    if (!_departmentEntity)
    {
        _departmentEntity = [[NSEntityDescription alloc] init];
        [_departmentEntity setName:@"Department"];
    }
    return _departmentEntity;
}

- (NSEntityDescription *)employeeEntity
{
    if (!_employeeEntity)
    {
        _employeeEntity = [[NSEntityDescription alloc] init];
        [_employeeEntity setName:@"Employee"];
    }
    return _employeeEntity;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel)
    {
        _managedObjectModel = [[NSManagedObjectModel alloc] init];
        NSMutableArray *entities = [NSMutableArray array];
        [entities addObject:[self departmentEntity]];
        [entities addObject:[self employeeEntity]];
        [_managedObjectModel setEntities:entities];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator)
    {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSString *storeType = NSInMemoryStoreType;
        NSError *error;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                       configuration:nil
                                                                 URL:nil
                                                             options:nil
                                                               error:&error])
        {
            NSLog(@"Error adding persistent store: %@", error);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)parentContext
{
    if (!_parentContext)
    {
        _parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_parentContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    }
    return _parentContext;
}

- (NSManagedObjectContext *)childContext
{
    if (!_childContext)
    {
        _childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_childContext setParentContext:[self parentContext]];
    }
    return _childContext;
}

- (void)setupEntityRelationships
{
    NSRelationshipDescription *departmentToEmployeeRelationship = [[NSRelationshipDescription alloc] init];
    NSRelationshipDescription *employeeToDepartmentRelationship = [[NSRelationshipDescription alloc] init];
    [departmentToEmployeeRelationship setName:@"employees"];
    [employeeToDepartmentRelationship setName:@"department"];
    [departmentToEmployeeRelationship setDestinationEntity:[self employeeEntity]];
    [employeeToDepartmentRelationship setDestinationEntity:[self departmentEntity]];
    [employeeToDepartmentRelationship setInverseRelationship:departmentToEmployeeRelationship];
    [employeeToDepartmentRelationship setMaxCount:1];
    [[self departmentEntity] setProperties:[NSArray arrayWithObject:departmentToEmployeeRelationship]];
    [[self employeeEntity] setProperties:[NSArray arrayWithObject:employeeToDepartmentRelationship]];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setupEntityRelationships];
    }
    return self;
}

@end
