/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2020 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UIControl+QMUI.m
//  qmui
//
//  Created by QMUI Team on 15/7/20.
//

#import "UIControl+QMUI.h"
#import <objc/runtime.h>
#import "QMUICore.h"

@interface UIControl ()

@property(nonatomic,assign) BOOL canSetHighlighted;
@property(nonatomic,assign) NSInteger touchEndCount;

@end

@implementation UIControl (QMUI)

QMUISynthesizeBOOLProperty(qmui_automaticallyAdjustTouchHighlightedInScrollView, setQmui_automaticallyAdjustTouchHighlightedInScrollView)
QMUISynthesizeBOOLProperty(canSetHighlighted, setCanSetHighlighted)
QMUISynthesizeNSIntegerProperty(touchEndCount, setTouchEndCount)
QMUISynthesizeIdCopyProperty(qmui_setHighlightedBlock, setQmui_setHighlightedBlock)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UIControl class], @selector(setHighlighted:), BOOL, ^(UIControl *selfObject, BOOL highlighted) {
            if (selfObject.qmui_setHighlightedBlock) {
                selfObject.qmui_setHighlightedBlock(highlighted);
            }
        });
        
        OverrideImplementation([UIControl class], @selector(removeTarget:action:forControlEvents:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIControl *selfObject, id target, SEL action, UIControlEvents controlEvents) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, id, SEL, UIControlEvents);
                originSelectorIMP = (void (*)(id, SEL, id, SEL, UIControlEvents))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, target, action, controlEvents);
                
                BOOL isTouchUpInsideEvent = controlEvents & UIControlEventTouchUpInside;
                BOOL shouldRemoveTouchUpInsideSelector = (action == @selector(qmui_handleTouchUpInside:)) || (target == selfObject && !action) || (!target && !action);
                if (isTouchUpInsideEvent && shouldRemoveTouchUpInsideSelector) {
                    // ???????????? setter ???????????? removeTarget????????????????????????
                    objc_setAssociatedObject(selfObject, &kAssociatedObjectKey_tapBlock, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
                }
            };
        });
        
        OverrideImplementation([UIControl class], @selector(touchesBegan:withEvent:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIControl *selfObject, NSSet *touches, UIEvent *event) {
                
                // call super
                void (^callSuperBlock)(void) = ^{
                    void (*originSelectorIMP)(id, SEL, NSSet *, UIEvent *);
                    originSelectorIMP = (void (*)(id, SEL, NSSet *, UIEvent *))originalIMPProvider();
                    originSelectorIMP(selfObject, originCMD, touches, event);
                };
                
                selfObject.touchEndCount = 0;
                if (selfObject.qmui_automaticallyAdjustTouchHighlightedInScrollView) {
                    selfObject.canSetHighlighted = YES;
                    callSuperBlock();
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (selfObject.canSetHighlighted) {
                            [selfObject setHighlighted:YES];
                        }
                    });
                } else {
                    callSuperBlock();
                }
            };
        });
        
        OverrideImplementation([UIControl class], @selector(touchesMoved:withEvent:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIControl *selfObject, NSSet *touches, UIEvent *event) {
                
                if (selfObject.qmui_automaticallyAdjustTouchHighlightedInScrollView) {
                    selfObject.canSetHighlighted = NO;
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, NSSet *, UIEvent *);
                originSelectorIMP = (void (*)(id, SEL, NSSet *, UIEvent *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, touches, event);
            };
        });
        
        OverrideImplementation([UIControl class], @selector(touchesEnded:withEvent:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIControl *selfObject, NSSet *touches, UIEvent *event) {
                
                if (selfObject.qmui_automaticallyAdjustTouchHighlightedInScrollView) {
                    selfObject.canSetHighlighted = NO;
                    if (selfObject.touchInside) {
                        [selfObject setHighlighted:YES];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            // ??????????????????????????????????????????????????????????????????????????????
                            // ?????? 3D Touch ?????????????????????????????????????????????????????????????????????????????????????????? touchesEnded ??????????????????
                            // ??? super touchEnded ?????????????????????????????????????????????????????????????????????????????????????????????// [selfObject qmui_touchesEnded:touches withEvent:event];
                            [selfObject sendActionsForAllTouchEventsIfCan];
                            if (selfObject.highlighted) {
                                [selfObject setHighlighted:NO];
                            }
                        });
                    } else {
                        [selfObject setHighlighted:NO];
                    }
                    return;
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, NSSet *, UIEvent *);
                originSelectorIMP = (void (*)(id, SEL, NSSet *, UIEvent *))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, touches, event);
            };
        });
        
        OverrideImplementation([UIControl class], @selector(touchesCancelled:withEvent:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UIControl *selfObject, NSSet *touches, UIEvent *event) {
                
                // call super
                void (^callSuperBlock)(void) = ^{
                    void (*originSelectorIMP)(id, SEL, NSSet *, UIEvent *);
                    originSelectorIMP = (void (*)(id, SEL, NSSet *, UIEvent *))originalIMPProvider();
                    originSelectorIMP(selfObject, originCMD, touches, event);
                };
                
                if (selfObject.qmui_automaticallyAdjustTouchHighlightedInScrollView) {
                    selfObject.canSetHighlighted = NO;
                    callSuperBlock();
                    if (selfObject.highlighted) {
                        [selfObject setHighlighted:NO];
                    }
                    return;
                }
                callSuperBlock();
            };
        });
    });
}

// ????????????????????????????????????????????????????????????????????????????????????????????????runtime??????????????????
// ?????????????????????.h?????????????????????????????????????????????
- (void)sendActionsForAllTouchEventsIfCan {
    self.touchEndCount += 1;
    if (self.touchEndCount == 1) {
        [self sendActionsForControlEvents:UIControlEventAllTouchEvents];
    }
}

#pragma mark - Tap Block

static char kAssociatedObjectKey_tapBlock;
- (void)setQmui_tapBlock:(void (^)(__kindof UIControl *))qmui_tapBlock {
    SEL action = @selector(qmui_handleTouchUpInside:);
    if (!qmui_tapBlock) {
        [self removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    objc_setAssociatedObject(self, &kAssociatedObjectKey_tapBlock, qmui_tapBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(__kindof UIControl *))qmui_tapBlock {
    return (void (^)(__kindof UIControl *))objc_getAssociatedObject(self, &kAssociatedObjectKey_tapBlock);
}

- (void)qmui_handleTouchUpInside:(__kindof UIControl *)sender {
    if (self.qmui_tapBlock) {
        self.qmui_tapBlock(self);
    }
}

@end
