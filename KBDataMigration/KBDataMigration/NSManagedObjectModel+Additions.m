//
//  NSManagedObjectModel+Additions.m
//  KBDataMigration
//
//  Created by 肖雄 on 17/5/2.
//  Copyright © 2017年 xiaoxiong. All rights reserved.
//

#import "NSManagedObjectModel+Additions.h"

@implementation NSManagedObjectModel (Additions)

+ (NSArray<NSManagedObjectModel *> *)modelVersionsForName:(NSString *)name
{
    NSArray *urls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"mom" subdirectory:[name stringByAppendingString:@".momd"]];
    NSMutableArray *models = [NSMutableArray array];
    for (id objc in urls) {
        if ([objc isKindOfClass:[NSURL class]]) {
            [models addObject:[[NSManagedObjectModel alloc] initWithContentsOfURL:objc]];
        }
    }
    
    return models;
}

- (BOOL)isEqualToManagerModel:(NSManagedObjectModel *)otherModel
{
    NSDictionary *firstEntity = self.entitiesByName;;
    NSDictionary *otherEntity = otherModel.entitiesByName;
    return [firstEntity isEqualToDictionary:otherEntity];
}

@end
