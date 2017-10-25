//
//  CoreDataStack.h
//  KuaiDiYuan_S
//
//  Created by 肖雄 on 15/10/13.
//  Copyright © 2015年 KuaidiHelp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataStack : NSObject

@property (nonatomic, strong) NSURL *modelURL;
@property (nonatomic, strong) NSURL *storeURL;

@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectContext *context;

- (instancetype)initWithModelName:(NSString *)modelName storeName:(NSString *)storeName migrate:(BOOL)migrate;

- (instancetype)initWithModelName:(NSString *)modelName
                        storeName:(NSString *)storeName
                 concurrentcyType:(NSManagedObjectContextConcurrencyType)concurrentcyType
                          migrate:(BOOL)migrate;

@end
