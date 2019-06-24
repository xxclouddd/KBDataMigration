//
//  NSManagedObjectModel+Additions.h
//  KBDataMigration
//
//  Created by 肖雄 on 17/5/2.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (Additions)

+ (NSArray<NSManagedObjectModel *> *)modelVersionsForName:(NSString *)name;
- (BOOL)isEqualToManagerModel:(NSManagedObjectModel *)otherModel;

@end
