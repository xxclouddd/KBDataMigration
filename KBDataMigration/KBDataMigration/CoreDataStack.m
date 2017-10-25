//
//  CoreDataStack.m
//  KuaiDiYuan_S
//
//  Created by 肖雄 on 15/10/13.
//  Copyright © 2015年 KuaidiHelp. All rights reserved.
//

#import "CoreDataStack.h"

@interface CoreDataStack ()

@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *storeName;
@property (nonatomic, strong) NSString *storePath;
//@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, assign) BOOL migrate;

@property (nonatomic, assign) NSManagedObjectContextConcurrencyType concurrentcyType;

@end

@implementation CoreDataStack

- (instancetype)initWithModelName:(NSString *)modelName storeName:(NSString *)storeName migrate:(BOOL)migrate
{
    self = [super init];
    if (self) {
        _modelName = modelName;
        _storeName = storeName;
        _migrate = migrate;
        _concurrentcyType = NSMainQueueConcurrencyType;
    }
    
    return self;
}

- (instancetype)initWithModelName:(NSString *)modelName
                        storeName:(NSString *)storeName
                 concurrentcyType:(NSManagedObjectContextConcurrencyType)concurrentcyType
                          migrate:(BOOL)migrate
{
    self = [super init];
    if (self) {
        _modelName = modelName;
        _storeName = storeName;
        _migrate = migrate;
        _concurrentcyType = concurrentcyType;
    }
    
    return self;
}

#pragma mark - setter and getter
- (NSURL *)modelURL
{
    return [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
}

- (NSURL *)storeURL
{
    NSArray *storePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *storePath = [storePaths lastObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return [NSURL fileURLWithPath:[storePath stringByAppendingPathComponent:[self.storeName stringByAppendingString:@".sqlite"]]];
}

- (NSManagedObjectModel *)model
{
    if (_model == nil) {
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    }
    return _model;
}

- (NSPersistentStoreCoordinator *)coordinator
{
    if (_coordinator == nil) {
        
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
        
        NSDictionary *options;
        if (_migrate) {
            options = @{NSMigratePersistentStoresAutomaticallyOption:@YES,
                        NSInferMappingModelAutomaticallyOption:@YES,
                        NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}
                        };
        } else {
            options = @{
                        NSMigratePersistentStoresAutomaticallyOption:@YES,
                        NSInferMappingModelAutomaticallyOption:@YES,
                        NSSQLitePragmasOption: @{@"journal_mode": @"WAL"}
                        };
        }
        
        NSError *error = nil;
        NSPersistentStore *persistentStore = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                        configuration:nil
                                                                                  URL:self.storeURL
                                                                              options:options
                                                                                error:&error];
        if (!persistentStore) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        // Reinstate the WAL journal_mode
        if (_migrate) {
            [_coordinator removePersistentStore:persistentStore error:NULL];
            
            options = @{NSMigratePersistentStoresAutomaticallyOption:@YES,
                        NSInferMappingModelAutomaticallyOption:@YES,
                        NSSQLitePragmasOption: @{@"journal_mode": @"WAL"}};
            persistentStore = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                         configuration:nil
                                                                   URL:self.storeURL
                                                               options:options error:&error];
            
            if (!persistentStore) {
                NSLog(@"Error adding persistent store %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }
    return _coordinator;
}

- (NSManagedObjectContext *)context
{
    if (_context == nil) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:_concurrentcyType];
        [_context setPersistentStoreCoordinator:self.coordinator];
    }
    return _context;
}

@end
