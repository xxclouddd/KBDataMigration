//
//  DataMigrationManager.h
//  KuaiDiYuan_S
//
//  Created by 肖雄 on 15/10/13.
//  Copyright © 2015年 KuaidiHelp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataStack.h"
#import <CoreData/CoreData.h>
#import "NSManagedObjectModel+Additions.h"

@class DataMigrationManager;

@protocol DataMigrationManagerDelegate <NSObject>

- (NSMappingModel *)migrationManager:(DataMigrationManager *)migrationManager
          mappingModelWithStoreModel:(NSManagedObjectModel *)storeModel;

- (NSManagedObjectModel *)migrationManager:(DataMigrationManager *)migrationManager
            destinationModelWithStoreModel:(NSManagedObjectModel *)storeModel;

@optional
- (void)migrationManager:(DataMigrationManager *)migrationManager migrationProgress:(float)migrationProgress;
@end


@interface DataMigrationManager : NSObject

@property (nonatomic, strong) CoreDataStack *stack;

@property (nonatomic, weak) id<DataMigrationManagerDelegate> delegate;

+ (NSString *)storePathWithName:(NSString *)name;

- (instancetype)initWithStoreNamed:(NSString *)storeName modelNamed:(NSString *)modelNamed delegate:(id<DataMigrationManagerDelegate>)delegate;

- (instancetype)initWithStoreNamed:(NSString *)storeName
                        modelNamed:(NSString *)modelNamed
                  concurrentcyType:(NSManagedObjectContextConcurrencyType)concurrentcyType
                          delegate:(id<DataMigrationManagerDelegate>)delegate;

@end
