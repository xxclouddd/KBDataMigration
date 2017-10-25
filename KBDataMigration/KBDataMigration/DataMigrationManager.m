//
//  DataMigrationManager.m
//  KuaiDiYuan_S
//
//  Created by 肖雄 on 15/10/13.
//  Copyright © 2015年 KuaidiHelp. All rights reserved.
//

#import "DataMigrationManager.h"

@interface DataMigrationManager ()

@property (nonatomic, strong) NSString *storeName;
@property (nonatomic, strong) NSString *modelName;

@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic, strong) NSManagedObjectModel *storeModel;
@property (nonatomic, strong) NSManagedObjectModel *currentModel;

@property (nonatomic, assign) NSManagedObjectContextConcurrencyType concurrentcyType;

@end

@implementation DataMigrationManager

- (instancetype)initWithStoreNamed:(NSString *)storeName
                        modelNamed:(NSString *)modelNamed
                          delegate:(id<DataMigrationManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.storeName = storeName;
        self.modelName = modelNamed;
        self.delegate = delegate;
        self.concurrentcyType = NSMainQueueConcurrencyType;
    }
    return self;
}

- (instancetype)initWithStoreNamed:(NSString *)storeName
                        modelNamed:(NSString *)modelNamed
                  concurrentcyType:(NSManagedObjectContextConcurrencyType)concurrentcyType
                          delegate:(id<DataMigrationManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.storeName = storeName;
        self.modelName = modelNamed;
        self.delegate = delegate;
        _concurrentcyType = concurrentcyType;
    }
    return self;
}

- (void)performMigration
{
    NSManagedObjectModel *destinationModel = nil;
    if ([self.delegate respondsToSelector:@selector(migrationManager:destinationModelWithStoreModel:)]) {
        destinationModel = [self.delegate migrationManager:self destinationModelWithStoreModel:self.storeModel];
    }
    
    if (!destinationModel) {
        return;
    }
    
    NSMappingModel *mappingModel = nil;
    if ([self.delegate respondsToSelector:@selector(migrationManager:mappingModelWithStoreModel:)]) {
        mappingModel = [self.delegate migrationManager:self mappingModelWithStoreModel:self.storeModel];
    }
    
    if ([self migreateStoreAtStoreURL:self.storeURL fromModel:self.storeModel toModel:destinationModel mappingModel:mappingModel]) {
        [self performMigration];
    }
}

- (BOOL)migreateStoreAtStoreURL:(NSURL *)storeURL fromModel:(NSManagedObjectModel *)from toModel:(NSManagedObjectModel *)to mappingModel:(NSMappingModel *)mappingModel
{
    NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:from destinationModel:to];
    
    NSMappingModel *migrationMappingModel;
    if (mappingModel) {
        migrationMappingModel = mappingModel;
    } else {
        NSError *error;
        migrationMappingModel = [NSMappingModel inferredMappingModelForSourceModel:from destinationModel:to error:&error];
    }
    
    NSURL *destionationURL = [storeURL URLByDeletingLastPathComponent];
    NSString *destionationName = [@"1" stringByAppendingString:[storeURL lastPathComponent]];
    NSURL *destionation = [destionationURL URLByAppendingPathComponent:destionationName];
    
    NSError *error;
    BOOL success = [migrationManager migrateStoreFromURL:storeURL
                                                    type:NSSQLiteStoreType
                                                 options:nil
                                        withMappingModel:migrationMappingModel
                                        toDestinationURL:destionation
                                         destinationType:NSSQLiteStoreType
                                      destinationOptions:nil
                                                   error:&error];
    if (success) {
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtURL:storeURL error:&error];
        [fileManager moveItemAtURL:destionation toURL:storeURL error:&error];
    } else {
        NSLog(@"Error migration:%@", error);
    }
    
    return success;
}

#pragma mark - helper
- (BOOL)storeIsCompatibleWithModel:(NSManagedObjectModel *)model
{
    NSDictionary *storeMetadata = [self metadataForStoreAtURL:self.storeURL];
    return [model isConfiguration:nil compatibleWithStoreMetadata:storeMetadata];
}

- (NSDictionary *)metadataForStoreAtURL:(NSURL *)storeURL
{
    NSError *error;
    NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeURL error:&error];
    if (metadata == nil) {
        NSLog(@"error:%@", error);
    }
    
    return metadata;
}

#pragma mark - setter and getter
- (NSURL *)storeURL
{
    NSArray *storePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *storePath = [storePaths lastObject];
    NSString *path = [NSString stringWithFormat:@"%@.sqlite", self.storeName];
    return [NSURL fileURLWithPath:[storePath stringByAppendingPathComponent:path]];
}

+ (NSString *)storePathWithName:(NSString *)name {
    NSArray *storePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *storePath = [storePaths lastObject];
    NSString *sqliteName = [NSString stringWithFormat:@"/%@.sqlite", name];
    return [storePath stringByAppendingString:sqliteName];
}

- (NSManagedObjectModel *)storeModel
{
    for (NSManagedObjectModel *model in [NSManagedObjectModel modelVersionsForName:self.modelName]) {
        if ([self storeIsCompatibleWithModel:model]) {
            return model;
        }
    }
    
    NSLog(@"Unable to determine storeModel");
    return nil;
}

- (NSManagedObjectModel *)currentModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel  alloc] initWithContentsOfURL:modelURL];
    return model;
}

- (CoreDataStack *)stack
{
    BOOL needMigrate = ![self storeIsCompatibleWithModel:self.currentModel];
    if (needMigrate) {
        [self performMigration];
    }
    
    //reference:
    //raywenderlich
    //http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
    //https://www.objc.io/issues/4-core-data/core-data-migration/
    //https://github.com/xxclouddd/issue-4-core-data-migration
    //https://developer.apple.com/library/ios/releasenotes/DataManagement/WhatsNew_CoreData_iOS/#//apple_ref/doc/uid/TP40013394-CH1-SW1
    
    return [[CoreDataStack alloc] initWithModelName:self.modelName storeName:self.storeName concurrentcyType:self.concurrentcyType migrate:needMigrate];
}

@end


