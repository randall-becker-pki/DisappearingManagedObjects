//
//  DisappearingManagedObjectsTests.m
//  DisappearingManagedObjectsTests
//
//  Created by Randall Becker on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DisappearingManagedObjectsTests.h"

#import "DataHelper.h"


@interface DisappearingManagedObjectsTests ()

@property (nonatomic, strong) DataHelper *helper;

@end


@implementation DisappearingManagedObjectsTests

@synthesize helper;

- (void)setUp
{
    [super setUp];
    
    self.helper = [[DataHelper alloc] init];
}

- (BOOL)departmentsFoundForEmployee:(NSManagedObject *)employee
                                inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:self.helper.departmentEntity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%@ IN employees", employee]];

    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results)
    {
        STFail(@"Error executing fetch request: %@", error);
    }

    if ([results count])
    {
        return YES;
    }

    return NO;
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    NSError *error;
    if (![context save:&error])
    {
        STFail(@"Error saving context: %@", error);
    }
}

- (void)testSavingToPersistentStoreConvertsMakesParentObjectIDPermanent
{
    NSManagedObjectContext *parentContext = self.helper.parentContext;
    NSEntityDescription *employeeEntity = self.helper.employeeEntity;

    // Create a managed object in a managed object context that has a persistent store.
    NSManagedObject *employee = [[NSManagedObject alloc] initWithEntity:employeeEntity
                                         insertIntoManagedObjectContext:parentContext];
    STAssertTrue([[employee objectID] isTemporaryID], @"The employee hasn't been saved to a persistent store.");

    // Save the context.
    [self saveContext:parentContext];
    STAssertFalse([[employee objectID] isTemporaryID], @"The employee has been saved to a persistent store.");
}

- (void)testSavingToPersistentStoreConvertsMakesChildObjectIDPermanent
{
    NSManagedObjectContext *parentContext = self.helper.parentContext;
    NSManagedObjectContext *childContext = self.helper.childContext;
    NSEntityDescription *employeeEntity = self.helper.employeeEntity;

    // Create a managed object in a child managed object context.
    NSManagedObject *employee = [[NSManagedObject alloc] initWithEntity:employeeEntity
                                         insertIntoManagedObjectContext:childContext];
    STAssertTrue([[employee objectID] isTemporaryID], @"The context hasn't been saved.");

    // Save the child context.
    [self saveContext:childContext];
    STAssertTrue([[employee objectID] isTemporaryID], @"The employee hasn't been saved to a persistent store.");// Succeeds, but I'm not certain it should.

    // Save the parent context.
    [self saveContext:parentContext];
    STAssertFalse([[employee objectID] isTemporaryID], @"The employee has been saved to a persistent store.");// Fails.

    // Work-around: Obtain permanent IDs for the child objects.
    NSError *error;
    if (![childContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:employee] error:&error])
    {
        STFail(@"Error obtaining permanent IDs: %@", error);
    }
    STAssertFalse([[employee objectID] isTemporaryID], @"A permanent ID was explicitly obtained.");// Succeeds.
}

- (void)testFetchingInParentContextMatchesRelatedObjects
{
    NSManagedObjectContext *parentContext = self.helper.parentContext;
    NSEntityDescription *employeeEntity = self.helper.employeeEntity;
    NSEntityDescription *departmentEntity = self.helper.departmentEntity;

    // Create related objects in a managed object context with a persistent store coordinator.
    NSManagedObject *department = [[NSManagedObject alloc] initWithEntity:departmentEntity
                                           insertIntoManagedObjectContext:parentContext];
    NSManagedObject *employee = [[NSManagedObject alloc] initWithEntity:employeeEntity
                                         insertIntoManagedObjectContext:parentContext];
    [employee setValue:department forKey:@"department"];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:parentContext], nil);

    // Save the context.
    [self saveContext:parentContext];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:parentContext], nil);
}

- (void)testFetchingInChildContextMatchesRelatedObjects
{
    NSManagedObjectContext *parentContext = self.helper.parentContext;
    NSManagedObjectContext *childContext = self.helper.childContext;
    NSEntityDescription *employeeEntity = self.helper.employeeEntity;
    NSEntityDescription *departmentEntity = self.helper.departmentEntity;

    // Create related objects in a child managed object context.
    NSManagedObject *department = [[NSManagedObject alloc] initWithEntity:departmentEntity
                                           insertIntoManagedObjectContext:childContext];

    NSManagedObject *employee = [[NSManagedObject alloc] initWithEntity:employeeEntity
                                         insertIntoManagedObjectContext:childContext];
    [employee setValue:department forKey:@"department"];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);

    // Save the child context.
    [self saveContext:childContext];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);// Succeeds.

    // Save the parent context.
    [self saveContext:parentContext];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);// Fails.
}

- (void)testFetchingInChildContextMatchesRelatedObjectsAfterObtainingPermanentIDs
{
    NSManagedObjectContext *parentContext = self.helper.parentContext;
    NSManagedObjectContext *childContext = self.helper.childContext;
    NSEntityDescription *employeeEntity = self.helper.employeeEntity;
    NSEntityDescription *departmentEntity = self.helper.departmentEntity;

    // Create related objects in a child managed object context.
    NSManagedObject *department = [[NSManagedObject alloc] initWithEntity:departmentEntity
                                           insertIntoManagedObjectContext:childContext];
    NSManagedObject *employee = [[NSManagedObject alloc] initWithEntity:employeeEntity
                                         insertIntoManagedObjectContext:childContext];
    [employee setValue:department forKey:@"department"];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);

    // Work-around: Obtain a permanent object IDs for the object referenced in the fetch request's predicate before saving the child context.
    NSError *error;
    if (![childContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:employee, nil] error:&error])
    {
        STFail(@"Error obtaining permanent IDs: %@", error);
    }
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);

    // Save the child context.
    [self saveContext:childContext];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);

    // Save the parent context.
    [self saveContext:parentContext];
    STAssertTrue([self departmentsFoundForEmployee:employee inContext:childContext], nil);// Succeeds.
}

@end
