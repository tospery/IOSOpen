/**
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2020 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

//
//  UISearchBar+QMUI.m
//  qmui
//
//  Created by QMUI Team on 16/5/26.
//

#import "UISearchBar+QMUI.h"
#import "QMUICore.h"
#import "UIImage+QMUI.h"
#import "UIView+QMUI.h"

@interface UISearchBar ()

@property(nonatomic, strong) NSString *qmuisb_centerPlaceholderCachedKey;
@property(nonatomic, assign) UIEdgeInsets qmuisb_customTextFieldMargins;
@end

@implementation UISearchBar (QMUI)

QMUISynthesizeBOOLProperty(qmui_usedAsTableHeaderView, setQmui_usedAsTableHeaderView)
QMUISynthesizeBOOLProperty(qmui_fixMaskViewLayoutBugAutomatically, setQmui_fixMaskViewLayoutBugAutomatically)
QMUISynthesizeUIEdgeInsetsProperty(qmuisb_customTextFieldMargins, setQmuisb_customTextFieldMargins)
QMUISynthesizeIdStrongProperty(qmuisb_centerPlaceholderCachedKey, setQmuisb_centerPlaceholderCachedKey)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        ExtendImplementationOfVoidMethodWithTwoArguments([UISearchBar class], @selector(setShowsCancelButton:animated:), BOOL, BOOL, ^(UISearchBar *selfObject, BOOL firstArgv, BOOL secondArgv) {
            if (selfObject.qmui_cancelButton && selfObject.qmui_cancelButtonFont) {
                selfObject.qmui_cancelButton.titleLabel.font = selfObject.qmui_cancelButtonFont;
            }
        });
        
        ExtendImplementationOfVoidMethodWithSingleArgument([UISearchBar class], @selector(setPlaceholder:), NSString *, (^(UISearchBar *selfObject, NSString *placeholder) {
            if (selfObject.qmui_placeholderColor || selfObject.qmui_font) {
                NSMutableAttributedString *string = selfObject.qmui_textField.attributedPlaceholder.mutableCopy;
                if (selfObject.qmui_placeholderColor) {
                    [string addAttribute:NSForegroundColorAttributeName value:selfObject.qmui_placeholderColor range:NSMakeRange(0, string.length)];
                }
                if (selfObject.qmui_font) {
                    [string addAttribute:NSFontAttributeName value:selfObject.qmui_font range:NSMakeRange(0, string.length)];
                }
                // ????????????????????????
                [string removeAttribute:NSShadowAttributeName range:NSMakeRange(0, string.length)];
                selfObject.qmui_textField.attributedPlaceholder = string.copy;
            }
        }));
        
        // iOS 13 ??????UISearchBar ?????? UITextField ??? _placeholderLabel ?????? didMoveToWindow ?????????????????? textColor?????????????????? searchBar ?????????????????????????????? placeholderColor ??????????????????????????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/830
        if (@available(iOS 13.0, *)) {
            ExtendImplementationOfVoidMethodWithoutArguments([UISearchBar class], @selector(didMoveToWindow), ^(UISearchBar *selfObject) {
                if (selfObject.qmui_placeholderColor) {
                    selfObject.placeholder = selfObject.placeholder;
                }
            });
        }

        if (@available(iOS 13.0, *)) {
            // -[_UISearchBarLayout applyLayout] ??? iOS 13 ????????????????????????????????????????????? -[UISearchBar layoutSubviews] ??????????????????????????????????????????
            Class _UISearchBarLayoutClass = NSClassFromString([NSString stringWithFormat:@"_%@%@",@"UISearchBar", @"Layout"]);
            OverrideImplementation(_UISearchBarLayoutClass, NSSelectorFromString(@"applyLayout"), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                return ^(UIView *selfObject) {
                    
                    // call super
                    void (^callSuperBlock)(void) = ^{
                        void (*originSelectorIMP)(id, SEL);
                        originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
                        originSelectorIMP(selfObject, originCMD);
                    };

                    UISearchBar *searchBar = (UISearchBar *)((UIView *)[selfObject qmui_valueForKey:[NSString stringWithFormat:@"_%@",@"searchBarBackground"]]).superview.superview;
                    
                    NSAssert(searchBar == nil || [searchBar isKindOfClass:[UISearchBar class]], @"not a searchBar");

                    if (searchBar && searchBar.qmui_searchController.isBeingDismissed && searchBar.qmui_usedAsTableHeaderView) {
                        CGRect previousRect = searchBar.qmui_backgroundView.frame;
                        callSuperBlock();
                        // applyLayout ?????????????????? _searchBarBackground  ??? frame ?????????????????? qmui_usedAsTableHeaderView ???????????????????????????????????????????????????
                        searchBar.qmui_backgroundView.frame = previousRect;
                    } else {
                        callSuperBlock();
                    }
                };
                
            });
            
            // iOS 13 ??????cancelButton ??? frame ??? -[_UISearchBarSearchContainerView layoutSubviews] ?????????
            Class _UISearchBarSearchContainerViewClass = NSClassFromString([NSString stringWithFormat:@"_%@%@",@"UISearchBarSearch", @"ContainerView"]);
            ExtendImplementationOfVoidMethodWithoutArguments(_UISearchBarSearchContainerViewClass, @selector(layoutSubviews), ^(UIView *selfObject) {
                UISearchBar *searchBar = (UISearchBar *)selfObject.superview.superview;
                NSAssert(searchBar == nil || [searchBar isKindOfClass:[UISearchBar class]], @"not a searchBar");
                [searchBar qmuisb_adjustCancelButtonFrameIfNeeded];
            });
            
            if (@available(iOS 14.0, *)) {
                // iOS 14 beta 1 ????????? searchTextField ??? font ??????????????? TextField ??????????????????????????? searchBarContainerView ????????????????????????????????????
                Class _UISearchBarContainerViewClass = NSClassFromString([NSString stringWithFormat:@"_%@%@",@"UISearchBar", @"ContainerView"]);
                OverrideImplementation(_UISearchBarContainerViewClass, @selector(setFrame:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
                    return ^(UIView *selfObject, CGRect frame) {
                        UISearchBar *searchBar = selfObject.subviews.firstObject;
                        if ([searchBar isKindOfClass:[UISearchBar class]]) {
                            if (searchBar.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView && searchBar.qmui_searchController.isBeingPresented) {
                                // ???????????????????????? statusBar ??????????????? containerView ?????????????????? statusBar ????????????
                                CGFloat currentStatusBarHeight = IS_NOTCHED_SCREEN ? StatusBarHeightConstant : StatusBarHeight;
                                if (frame.origin.y < currentStatusBarHeight + NavigationBarHeight) {
                                    // ???????????????????????? statusBar ????????????????????????????????????????????? 50??????????????????????????? 56
                                    frame.size.height = MAX(UISearchBar.qmuisb_seachBarDefaultActiveHeight + currentStatusBarHeight, 56);
                                    frame.origin.y = 0;
                                }
                            }
                        }
                        void (*originSelectorIMP)(id, SEL, CGRect);
                        originSelectorIMP = (void (*)(id, SEL, CGRect))originalIMPProvider();
                        originSelectorIMP(selfObject, originCMD, frame);
                    };
                });
            }
        }
        
        Class UISearchBarTextFieldClass = NSClassFromString([NSString stringWithFormat:@"%@%@",@"UISearchBarText", @"Field"]);
        OverrideImplementation(UISearchBarTextFieldClass, @selector(setFrame:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UITextField *textField, CGRect frame) {
                
                UISearchBar *searchBar = nil;
                if (@available(iOS 13.0, *)) {
                    searchBar = (UISearchBar *)textField.superview.superview.superview;
                } else {
                    searchBar = (UISearchBar *)textField.superview.superview;
                }
                
                NSAssert(searchBar == nil || [searchBar isKindOfClass:[UISearchBar class]], @"not a searchBar");
                
                if (searchBar) {
                    frame = [searchBar qmuisb_adjustedSearchTextFieldFrameByOriginalFrame:frame];
                }
                
                void (*originSelectorIMP)(id, SEL, CGRect);
                originSelectorIMP = (void (*)(id, SEL, CGRect))originalIMPProvider();
                originSelectorIMP(textField, originCMD, frame);
                
                [searchBar qmuisb_searchTextFieldFrameDidChange];
            };
        });
        
        
        ExtendImplementationOfVoidMethodWithoutArguments([UISearchBar class], @selector(layoutSubviews), ^(UISearchBar *selfObject) {
            // ?????? iOS 13 backgroundView ??????????????????????????????
            if (IOS_VERSION >= 13.0 && selfObject.qmui_usedAsTableHeaderView && selfObject.qmui_isActive) {
                selfObject.qmui_backgroundView.qmui_height = StatusBarHeightConstant + selfObject.qmui_height;
                selfObject.qmui_backgroundView.qmui_top = -StatusBarHeightConstant;
            }
            [selfObject qmuisb_adjustCancelButtonFrameIfNeeded];
            [selfObject qmuisb_fixDismissingAnimationIfNeeded];
            [selfObject qmuisb_fixSearchResultsScrollViewContentInsetIfNeeded];
            
        });
        
        OverrideImplementation([UISearchBar class], @selector(setFrame:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISearchBar *selfObject, CGRect frame) {
                
                frame = [selfObject qmuisb_adjustedSearchBarFrameByOriginalFrame:frame];
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGRect);
                originSelectorIMP = (void (*)(id, SEL, CGRect))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, frame);
                
            };
        });
        
        // [UIKit Bug] ??? UISearchController.searchBar ?????? tableHeaderView ?????????????????????????????? 1px ??????????????????????????????
        // https://github.com/Tencent/QMUI_iOS/issues/950
        OverrideImplementation([UISearchBar class], NSSelectorFromString(@"_setMaskBounds:"), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UISearchBar *selfObject, CGRect firstArgv) {
                
                BOOL shouldFixBug = selfObject.qmui_fixMaskViewLayoutBugAutomatically
                && selfObject.qmui_searchController
                && [selfObject.superview isKindOfClass:UITableView.class]
                && ((UITableView *)selfObject.superview).tableHeaderView == selfObject;
                if (shouldFixBug) {
                    firstArgv = CGRectMake(CGRectGetMinX(firstArgv), CGRectGetMinY(firstArgv) - PixelOne, CGRectGetWidth(firstArgv), CGRectGetHeight(firstArgv) + PixelOne);
                }
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGRect);
                originSelectorIMP = (void (*)(id, SEL, CGRect))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, firstArgv);
            };
        });
        
        ExtendImplementationOfNonVoidMethodWithSingleArgument([UISearchBar class], @selector(initWithFrame:), CGRect, UISearchBar *, ^UISearchBar *(UISearchBar *selfObject, CGRect firstArgv, UISearchBar *originReturnValue) {
            [originReturnValue qmuisb_didInitialize];
            return originReturnValue;
        });
        
        ExtendImplementationOfNonVoidMethodWithSingleArgument([UISearchBar class], @selector(initWithCoder:), NSCoder *, UISearchBar *, ^UISearchBar *(UISearchBar *selfObject, NSCoder *firstArgv, UISearchBar *originReturnValue) {
            [originReturnValue qmuisb_didInitialize];
            return originReturnValue;
        });
    });
}

- (void)qmuisb_didInitialize {
    self.qmui_showsLeftAccessoryView = YES;
    self.qmui_showsRightAccessoryView = YES;
    
    if (QMUICMIActivated && ShouldFixSearchBarMaskViewLayoutBug) {
        self.qmui_fixMaskViewLayoutBugAutomatically = YES;
    }
}

static char kAssociatedObjectKey_centerPlaceholder;
- (void)setQmui_centerPlaceholder:(BOOL)qmui_centerPlaceholder {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_centerPlaceholder, @(qmui_centerPlaceholder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.qmuisb_centerPlaceholderCachedKey = nil;
    
    __weak __typeof(self)weakSelf = self;
    if (qmui_centerPlaceholder) {
        self.qmui_textField.qmui_layoutSubviewsBlock = ^(UITextField * _Nonnull textField) {
            
            // ?????????????????? textField ???????????????????????????????????? CGRectGetWidth() ???????????????????????????????????????????????? bounds.size.width ?????????????????????????????? CGRectGetWidth()
            if (textField.bounds.size.width <= 0) return;
            
            if (textField.isEditing || textField.text.length > 0) {
                weakSelf.qmuisb_centerPlaceholderCachedKey = nil;
                if (!UIOffsetEqualToOffset(UIOffsetZero, [weakSelf positionAdjustmentForSearchBarIcon:UISearchBarIconSearch])) {
                    [weakSelf setPositionAdjustment:UIOffsetZero forSearchBarIcon:UISearchBarIconSearch];
                    [textField layoutIfNeeded];// ?????????????????????????????? positionAdjustment ???????????????????????????????????????
                }
            } else {
                UIView *leftView = [textField qmui_valueForKey:@"leftView"];
                UILabel *label = [textField qmui_valueForKey:@"placeholderLabel"];
                CGFloat width = CGRectGetMaxX(label.frame) - CGRectGetMinX(leftView.frame);
                NSString *cachedKey = [NSString stringWithFormat:@"%.0f-%.f", CGRectGetWidth(textField.bounds), CGFloatToFixed(width, 0)];
                if (![cachedKey isEqualToString:weakSelf.qmuisb_centerPlaceholderCachedKey]) {
                    weakSelf.qmuisb_centerPlaceholderCachedKey = cachedKey;
                    CGFloat searchIconDefaultMarginLeft = 6; // ?????????????????? icon ???????????? textField ??????????????????????????????????????????????????????????????? positionAdjustment ???????????????????????????????????????????????????
                    CGFloat horizontal = CGFloatGetCenter(CGRectGetWidth(textField.bounds), width) - searchIconDefaultMarginLeft;
                    [weakSelf setPositionAdjustment:UIOffsetMake(horizontal, 0) forSearchBarIcon:UISearchBarIconSearch];
                    [textField layoutIfNeeded];// ?????????????????????????????? positionAdjustment ???????????????????????????????????????
                }
            }
        };
        [self.qmui_textField setNeedsLayout];
    } else {
        self.qmui_textField.qmui_layoutSubviewsBlock = nil;
        [self setPositionAdjustment:UIOffsetZero forSearchBarIcon:UISearchBarIconSearch];
    }
}

- (BOOL)qmui_centerPlaceholder {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_centerPlaceholder)) boolValue];
}

static char kAssociatedObjectKey_PlaceholderColor;
- (void)setQmui_placeholderColor:(UIColor *)qmui_placeholderColor {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_PlaceholderColor, qmui_placeholderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.placeholder) {
        // ?????? setPlaceholder ????????? placeholder ???????????????
        self.placeholder = self.placeholder;
    }
}

- (UIColor *)qmui_placeholderColor {
    return (UIColor *)objc_getAssociatedObject(self, &kAssociatedObjectKey_PlaceholderColor);
}

static char kAssociatedObjectKey_TextColor;
- (void)setQmui_textColor:(UIColor *)qmui_textColor {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_TextColor, qmui_textColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.qmui_textField.textColor = qmui_textColor;
}

- (UIColor *)qmui_textColor {
    return (UIColor *)objc_getAssociatedObject(self, &kAssociatedObjectKey_TextColor);
}

static char kAssociatedObjectKey_font;
- (void)setQmui_font:(UIFont *)qmui_font {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_font, qmui_font, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.placeholder) {
        // ?????? setPlaceholder ????????? placeholder ???????????????
        self.placeholder = self.placeholder;
    }
    
    // ??????????????????????????????
    self.qmui_textField.font = qmui_font;
}

- (UIFont *)qmui_font {
    return (UIFont *)objc_getAssociatedObject(self, &kAssociatedObjectKey_font);
}

- (UITextField *)qmui_textField {
    if (@available(iOS 13.0, *)) {
        return self.searchTextField;
    }
    UITextField *textField = [self qmui_valueForKey:@"searchField"];
    return textField;
}

- (UIButton *)qmui_cancelButton {
    UIButton *cancelButton = [self qmui_valueForKey:@"cancelButton"];
    return cancelButton;
}

static char kAssociatedObjectKey_cancelButtonFont;
- (void)setQmui_cancelButtonFont:(UIFont *)qmui_cancelButtonFont {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_cancelButtonFont, qmui_cancelButtonFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.qmui_cancelButton.titleLabel.font = qmui_cancelButtonFont;
}

- (UIFont *)qmui_cancelButtonFont {
    return (UIFont *)objc_getAssociatedObject(self, &kAssociatedObjectKey_cancelButtonFont);
}

static char kAssociatedObjectKey_textFieldMargins;
- (void)setQmui_textFieldMargins:(UIEdgeInsets)qmui_textFieldMargins {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_textFieldMargins, @(qmui_textFieldMargins), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self qmuisb_setNeedsLayoutTextField];
}

- (UIEdgeInsets)qmui_textFieldMargins {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_textFieldMargins)) UIEdgeInsetsValue];
}

- (UISegmentedControl *)qmui_segmentedControl {
    UISegmentedControl *segmentedControl = [self qmui_valueForKey:@"scopeBar"];
    return segmentedControl;
}

- (BOOL)qmui_isActive {
    return (self.qmui_searchController.isBeingPresented || self.qmui_searchController.isActive);
}

- (UISearchController *)qmui_searchController {
    return [self qmui_valueForKey:@"_searchController"];
}

- (UIView *)qmui_backgroundView {
    BeginIgnorePerformSelectorLeaksWarning
    UIView *backgroundView = [self performSelector:NSSelectorFromString(@"_backgroundView")];
    EndIgnorePerformSelectorLeaksWarning
    return backgroundView;
}

- (void)qmui_styledAsQMUISearchBar {
    if (!QMUICMIActivated) {
        return;
    }
    
    // ????????????????????? placeholder ?????????
    self.qmui_font = SearchBarFont;

    // ????????????????????????
    self.qmui_textColor = SearchBarTextColor;

    // placeholder ???????????????
    self.qmui_placeholderColor = SearchBarPlaceholderColor;

    self.placeholder = @"??????";
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;

    // ????????????icon
    UIImage *searchIconImage = SearchBarSearchIconImage;
    if (searchIconImage) {
        if (!CGSizeEqualToSize(searchIconImage.size, CGSizeMake(14, 14))) {
            NSLog(@"???????????????????????????SearchBarSearchIconImage????????????????????? (14, 14)??????????????????????????????????????? %@", NSStringFromCGSize(searchIconImage.size));
        }
        [self setImage:searchIconImage forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    }

    // ????????????????????????????????????icon
    UIImage *clearIconImage = SearchBarClearIconImage;
    if (clearIconImage) {
        [self setImage:clearIconImage forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    }

    // ??????SearchBar??????????????????
    self.tintColor = SearchBarTintColor;

    // ??????????????????
    UIImage *searchFieldBackgroundImage = SearchBarTextFieldBackgroundImage;
    if (searchFieldBackgroundImage) {
        [self setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
    }
    
    // ???????????????
    UIColor *textFieldBorderColor = SearchBarTextFieldBorderColor;
    if (textFieldBorderColor) {
        self.qmui_textField.layer.borderWidth = PixelOne;
        self.qmui_textField.layer.borderColor = textFieldBorderColor.CGColor;
    }
    
    // ??????bar?????????
    // ????????? searchBar ?????????????????????????????????????????????????????? barTintColor ??????????????????????????? backgroundImage
    UIImage *backgroundImage = SearchBarBackgroundImage;
    if (backgroundImage) {
        [self setBackgroundImage:backgroundImage forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [self setBackgroundImage:backgroundImage forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefaultPrompt];
    }
}

+ (UIImage *)qmui_generateTextFieldBackgroundImageWithColor:(UIColor *)color {
    // ?????????????????????????????????????????????????????? iOS 11 ????????????????????????????????? 36???iOS 10 ????????????????????? 28 ?????????????????????????????????:QMUIKit/UIKitExtensions/UISearchBar+QMUI.m
    // ?????????????????????????????? UIView ???????????????????????????????????????
    return [[UIImage qmui_imageWithColor:color size:self.qmuisb_textFieldDefaultSize cornerRadius:0] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

+ (UIImage *)qmui_generateBackgroundImageWithColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor {
    UIImage *backgroundImage = nil;
    if (backgroundColor || borderColor) {
        backgroundImage = [UIImage qmui_imageWithColor:backgroundColor ?: UIColorWhite size:CGSizeMake(10, 10) cornerRadius:0];
        if (borderColor) {
            backgroundImage = [backgroundImage qmui_imageWithBorderColor:borderColor borderWidth:PixelOne borderPosition:QMUIImageBorderPositionBottom];
        }
        backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    }
    return backgroundImage;
}

#pragma mark - Left Accessory View

static char kAssociatedObjectKey_showsLeftAccessoryView;
- (void)qmui_setShowsLeftAccessoryView:(BOOL)showsLeftAccessoryView animated:(BOOL)animated {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_showsLeftAccessoryView, @(showsLeftAccessoryView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (animated) {
        if (showsLeftAccessoryView) {
            self.qmui_leftAccessoryView.hidden = NO;
            self.qmui_leftAccessoryView.frame = CGRectSetXY(self.qmui_leftAccessoryView.frame, -CGRectGetWidth(self.qmui_leftAccessoryView.frame), CGRectGetMinYVerticallyCenter(self.qmui_textField.frame, self.qmui_leftAccessoryView.frame));
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self qmuisb_updateCustomTextFieldMargins];
            } completion:nil];
        } else {
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.qmui_leftAccessoryView.transform = CGAffineTransformMakeTranslation(-CGRectGetMaxX(self.qmui_leftAccessoryView.frame), 0);
                [self qmuisb_updateCustomTextFieldMargins];
            } completion:^(BOOL finished) {
                self.qmui_leftAccessoryView.hidden = YES;
                self.qmui_leftAccessoryView.transform = CGAffineTransformIdentity;
            }];
        }
    } else {
        self.qmui_leftAccessoryView.hidden = !showsLeftAccessoryView;
        [self qmuisb_updateCustomTextFieldMargins];
    }
}

- (void)setQmui_showsLeftAccessoryView:(BOOL)qmui_showsLeftAccessoryView {
    [self qmui_setShowsLeftAccessoryView:qmui_showsLeftAccessoryView animated:NO];
}

- (BOOL)qmui_showsLeftAccessoryView {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_showsLeftAccessoryView)) boolValue];
}

static char kAssociatedObjectKey_leftAccessoryView;
- (void)setQmui_leftAccessoryView:(UIView *)qmui_leftAccessoryView {
    if (self.qmui_leftAccessoryView != qmui_leftAccessoryView) {
        [self.qmui_leftAccessoryView removeFromSuperview];
        [self.qmui_textField.superview addSubview:qmui_leftAccessoryView];
    }
    objc_setAssociatedObject(self, &kAssociatedObjectKey_leftAccessoryView, qmui_leftAccessoryView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    qmui_leftAccessoryView.hidden = !self.qmui_showsLeftAccessoryView;
    [qmui_leftAccessoryView sizeToFit];
    
    [self qmuisb_updateCustomTextFieldMargins];
}

- (UIView *)qmui_leftAccessoryView {
    return (UIView *)objc_getAssociatedObject(self, &kAssociatedObjectKey_leftAccessoryView);
}

static char kAssociatedObjectKey_leftAccessoryViewMargins;
- (void)setQmui_leftAccessoryViewMargins:(UIEdgeInsets)qmui_leftAccessoryViewMargins {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_leftAccessoryViewMargins, @(qmui_leftAccessoryViewMargins), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self qmuisb_updateCustomTextFieldMargins];
}

- (UIEdgeInsets)qmui_leftAccessoryViewMargins {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_leftAccessoryViewMargins)) UIEdgeInsetsValue];
}

// ?????????????????? textField ?????????????????????????????????????????????????????? textField ??????????????????????????????
- (void)qmuisb_adjustLeftAccessoryViewFrameAfterTextFieldLayout {
    if (self.qmui_leftAccessoryView && !self.qmui_leftAccessoryView.hidden) {
        self.qmui_leftAccessoryView.qmui_frameApplyTransform = CGRectSetXY(self.qmui_leftAccessoryView.frame, CGRectGetMinX(self.qmui_textField.frame) - [UISearchBar qmuisb_textFieldDefaultMargins].left - self.qmui_leftAccessoryViewMargins.right - CGRectGetWidth(self.qmui_leftAccessoryView.frame), CGRectGetMinYVerticallyCenter(self.qmui_textField.frame, self.qmui_leftAccessoryView.frame));
    }
}

#pragma mark - Right Accessory View

static char kAssociatedObjectKey_showsRightAccessoryView;
- (void)qmui_setShowsRightAccessoryView:(BOOL)showsRightAccessoryView animated:(BOOL)animated {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_showsRightAccessoryView, @(showsRightAccessoryView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (animated) {
        BOOL shouldAnimateAlpha = self.showsCancelButton;// ?????? rightAccessoryView ?????? cancelButton ?????????????????????????????????????????????????????? alpha ??????
        if (showsRightAccessoryView) {
            self.qmui_rightAccessoryView.hidden = NO;
            self.qmui_rightAccessoryView.qmui_frameApplyTransform = CGRectSetXY(self.qmui_rightAccessoryView.frame, CGRectGetWidth(self.qmui_rightAccessoryView.superview.bounds), CGRectGetMinYVerticallyCenter(self.qmui_textField.frame, self.qmui_rightAccessoryView.frame));
            if (shouldAnimateAlpha) {
                self.qmui_rightAccessoryView.alpha = 0;
            }
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self qmuisb_updateCustomTextFieldMargins];
                if (shouldAnimateAlpha) {
                    self.qmui_rightAccessoryView.alpha = 1;
                }
            } completion:nil];
        } else {
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.qmui_rightAccessoryView.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(self.qmui_rightAccessoryView.superview.bounds) - CGRectGetMinX(self.qmui_rightAccessoryView.frame), 0);
                [self qmuisb_updateCustomTextFieldMargins];
            } completion:^(BOOL finished) {
                self.qmui_rightAccessoryView.hidden = YES;
                self.qmui_rightAccessoryView.transform = CGAffineTransformIdentity;
                self.qmui_rightAccessoryView.alpha = 1;
            }];
            if (shouldAnimateAlpha) {
                [UIView animateWithDuration:.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    self.qmui_rightAccessoryView.alpha = 0;
                } completion:nil];
            }
        }
    } else {
        self.qmui_rightAccessoryView.hidden = !showsRightAccessoryView;
        [self qmuisb_updateCustomTextFieldMargins];
    }
}

- (void)setQmui_showsRightAccessoryView:(BOOL)qmui_showsRightAccessoryView {
    [self qmui_setShowsRightAccessoryView:qmui_showsRightAccessoryView animated:NO];
}

- (BOOL)qmui_showsRightAccessoryView {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_showsRightAccessoryView)) boolValue];
}

static char kAssociatedObjectKey_rightAccessoryView;
- (void)setQmui_rightAccessoryView:(UIView *)qmui_rightAccessoryView {
    if (self.qmui_rightAccessoryView != qmui_rightAccessoryView) {
        [self.qmui_rightAccessoryView removeFromSuperview];
        [self.qmui_textField.superview addSubview:qmui_rightAccessoryView];
    }
    objc_setAssociatedObject(self, &kAssociatedObjectKey_rightAccessoryView, qmui_rightAccessoryView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    qmui_rightAccessoryView.hidden = !self.qmui_showsRightAccessoryView;
    [qmui_rightAccessoryView sizeToFit];
    
    [self qmuisb_updateCustomTextFieldMargins];
}

- (UIView *)qmui_rightAccessoryView {
    return (UIView *)objc_getAssociatedObject(self, &kAssociatedObjectKey_rightAccessoryView);
}

static char kAssociatedObjectKey_rightAccessoryViewMargins;
- (void)setQmui_rightAccessoryViewMargins:(UIEdgeInsets)qmui_rightAccessoryViewMargins {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_rightAccessoryViewMargins, @(qmui_rightAccessoryViewMargins), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self qmuisb_updateCustomTextFieldMargins];
}

- (UIEdgeInsets)qmui_rightAccessoryViewMargins {
    return [((NSNumber *)objc_getAssociatedObject(self, &kAssociatedObjectKey_rightAccessoryViewMargins)) UIEdgeInsetsValue];
}

- (void)qmuisb_updateCustomTextFieldMargins {
    // ??? qmui_showsLeftAccessoryView ???????????? !qmui_leftAccessoryView.hidden ??????????????????????????? hidden ?????????????????????????????????????????????
    BOOL shouldShowLeftAccessoryView = self.qmui_showsLeftAccessoryView && self.qmui_leftAccessoryView;
    BOOL shouldShowRightAccessoryView = self.qmui_showsRightAccessoryView && self.qmui_rightAccessoryView;
    CGFloat leftMargin = shouldShowLeftAccessoryView ? CGRectGetWidth(self.qmui_leftAccessoryView.frame) + UIEdgeInsetsGetHorizontalValue(self.qmui_leftAccessoryViewMargins) : 0;
    CGFloat rightMargin = shouldShowRightAccessoryView ? CGRectGetWidth(self.qmui_rightAccessoryView.frame) + UIEdgeInsetsGetHorizontalValue(self.qmui_rightAccessoryViewMargins) : 0;
    
    if (self.qmuisb_customTextFieldMargins.left != leftMargin || self.qmuisb_customTextFieldMargins.right != rightMargin) {
        self.qmuisb_customTextFieldMargins = UIEdgeInsetsMake(self.qmuisb_customTextFieldMargins.top, leftMargin, self.qmuisb_customTextFieldMargins.bottom, rightMargin);
        [self qmuisb_setNeedsLayoutTextField];
    }
}

// ?????????????????? textField ?????????????????????????????????????????????????????? textField ??????????????????????????????
- (void)qmuisb_adjustRightAccessoryViewFrameAfterTextFieldLayout {
    if (self.qmui_rightAccessoryView && !self.qmui_rightAccessoryView.hidden) {
        self.qmui_rightAccessoryView.qmui_frameApplyTransform = CGRectSetXY(self.qmui_rightAccessoryView.frame, CGRectGetMaxX(self.qmui_textField.frame) + [UISearchBar qmuisb_textFieldDefaultMargins].right + self.qmui_textFieldMargins.right + self.qmui_rightAccessoryViewMargins.left, CGRectGetMinYVerticallyCenter(self.qmui_textField.frame, self.qmui_rightAccessoryView.frame));
    }
}

#pragma mark - Layout

- (void)qmuisb_setNeedsLayoutTextField {
    if (self.qmui_textField) {
        if (@available(iOS 13.0, *)) {
            [self.qmui_textField.superview setNeedsLayout];
            [self.qmui_textField.superview layoutIfNeeded];
        } else {
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }
    }
}

- (BOOL)qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView {
    if (@available(iOS 11, *)) {
        return self.qmui_usedAsTableHeaderView && self.qmui_searchController.hidesNavigationBarDuringPresentation;
    }
    return NO;
}

- (void)qmuisb_adjustCancelButtonFrameIfNeeded  {
    if (!self.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView) return;
    
    CGRect textFieldFrame = self.qmui_textField.frame;
    
    BOOL shouldFixCancelButton = NO;
    if (@available(iOS 13.0, *)) {
        shouldFixCancelButton = YES;// iOS 13 ??? searchBar ?????? tableHeaderView ???????????????????????????????????? searchBar.showsCancelButton = YES???????????????????????????????????????????????? cancelButton ???????????????????????????
    } else {
        shouldFixCancelButton = [self qmui_isActive];
    }
    if (shouldFixCancelButton) {
        self.qmui_cancelButton.qmui_top = CGRectGetMinYVerticallyCenter(textFieldFrame, self.qmui_cancelButton.frame);
    }
    
    if ([self qmui_isActive]) {
        if (self.qmui_segmentedControl.superview.qmui_top < self.qmui_textField.qmui_bottom) {
            // scopeBar ????????????????????????
            self.qmui_segmentedControl.superview.qmui_top = CGRectGetMinYVerticallyCenter(textFieldFrame, self.qmui_segmentedControl.superview.frame);
        }
    }
}

- (CGRect)qmuisb_adjustedSearchBarFrameByOriginalFrame:(CGRect)frame {
    if (!self.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView) return frame;
    
    // ?????? setFrame: ??????????????? issue???https://github.com/Tencent/QMUI_iOS/issues/233
    // iOS 11 ?????? tableHeaderView ??????????????? searchBar ?????????????????????????????? y ??????????????????????????????
    // iOS 13 iPad ?????????????????? y ??????????????????????????????
    
    if (self.qmui_searchController.isBeingDismissed && CGRectGetMinY(frame) < 0) {
        frame = CGRectSetY(frame, 0);
    }
    
    if (![self qmui_isActive]) {
        return frame;
    }
    
    if (IS_NOTCHED_SCREEN) {
        // ??????
        if (CGRectGetMinY(frame) == 38) {
            // searching
            frame = CGRectSetY(frame, 44);
        }
        
        // ????????? iPad
        if (CGRectGetMinY(frame) == 18) {
            // searching
            frame = CGRectSetY(frame, 24);
        }
        
        // ??????
        if (CGRectGetMinY(frame) == -6) {
            frame = CGRectSetY(frame, 0);
        }
    } else {
        
        // ??????
        if (CGRectGetMinY(frame) == 14) {
            frame = CGRectSetY(frame, 20);
        }
        
        // ??????
        if (CGRectGetMinY(frame) == -6) {
            frame = CGRectSetY(frame, 0);
        }
    }
    // ???????????????????????? ???????????? 56???????????????????????????????????? (iOS 11 ????????????????????????????????????????????? 50???????????????????????? 55)
    if (frame.size.height != 56) {
        frame.size.height = 56;
    }
    return frame;
}

- (CGRect)qmuisb_adjustedSearchTextFieldFrameByOriginalFrame:(CGRect)frame {
    if (self.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView) {
        if (@available(iOS 14.0, *)) {
            // iOS 14 beta 1 ????????? searchTextField ??? font ??????????????? TextField ?????????????????????????????????
            CGFloat fixedHeight = UISearchBar.qmuisb_textFieldDefaultSize.height;
            CGFloat offset = fixedHeight - frame.size.height;
            frame.origin.y -= offset / 2.0;
            frame.size.height = fixedHeight;
        }
        if (self.qmui_searchController.isBeingPresented) {
            BOOL statusBarHidden = NO;
            if (@available(iOS 13.0, *)) {
                statusBarHidden = self.window.windowScene.statusBarManager.statusBarHidden;
            } else {
                statusBarHidden = UIApplication.sharedApplication.statusBarHidden;
            }
            CGFloat visibleHeight = statusBarHidden ? 56 : 50;
            frame.origin.y = (visibleHeight - self.qmui_textField.qmui_height) / 2;
        } else if (self.qmui_searchController.isBeingDismissed) {
            frame.origin.y = (56 - self.qmui_textField.qmui_height) / 2;
        }
    }
    
    // apply qmui_textFieldMargins
    if (!UIEdgeInsetsEqualToEdgeInsets(self.qmui_textFieldMargins, UIEdgeInsetsZero)) {
        frame = CGRectInsetEdges(frame, self.qmui_textFieldMargins);
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.qmuisb_customTextFieldMargins, UIEdgeInsetsZero)) {
        frame = CGRectInsetEdges(frame, self.qmuisb_customTextFieldMargins);
    }
    
    return frame;
}

- (void)qmuisb_searchTextFieldFrameDidChange {
    // apply SearchBarTextFieldCornerRadius
    CGFloat textFieldCornerRadius = SearchBarTextFieldCornerRadius;
    if (textFieldCornerRadius != 0) {
        textFieldCornerRadius = textFieldCornerRadius > 0 ? textFieldCornerRadius : CGRectGetHeight(self.qmui_textField.frame) / 2.0;
    }
    self.qmui_textField.layer.cornerRadius = textFieldCornerRadius;
    self.qmui_textField.clipsToBounds = textFieldCornerRadius != 0;
    
    [self qmuisb_adjustLeftAccessoryViewFrameAfterTextFieldLayout];
    [self qmuisb_adjustRightAccessoryViewFrameAfterTextFieldLayout];
    [self qmuisb_adjustCancelButtonFrameIfNeeded];
}

- (void)qmuisb_fixDismissingAnimationIfNeeded {
    if (!self.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView) return;
    
    if (self.qmui_searchController.isBeingDismissed) {
        
        if (IS_NOTCHED_SCREEN && self.frame.origin.y == 43) { // ????????????????????????????????????????????? pt
            self.frame = CGRectSetY(self.frame, StatusBarHeightConstant);
        }
        
        UIView *searchBarContainerView = self.superview;
        // ????????????????????????searchBarContainerView ????????????????????????
        if (searchBarContainerView.layer.masksToBounds == YES) {
            searchBarContainerView.layer.masksToBounds = NO;
            // backgroundView ??? searchBarContainerView masksToBounds ?????????????????????
            CGFloat backgroundViewBottomClipped = CGRectGetMaxY([searchBarContainerView convertRect:self.qmui_backgroundView.frame fromView:self.qmui_backgroundView.superview]) - CGRectGetHeight(searchBarContainerView.bounds);
            // UISeachbar ???????????????????????? BackgroundView ??????????????? searchBarContainerView???????????????????????????????????????
            if (backgroundViewBottomClipped > 0) {
                CGFloat previousHeight = self.qmui_backgroundView.qmui_height;
                [UIView performWithoutAnimation:^{
                    // ????????? backgroundViewBottomClipped ?????? backgroundView ??? searchBarContainerView ????????????????????????????????????????????? animationBlock ??????????????????????????? performWithoutAnimation ????????????
                    self.qmui_backgroundView.qmui_height -= backgroundViewBottomClipped;
                }];
                // ??????????????????????????? animationBlock ?????????????????????????????????????????????
                self.qmui_backgroundView.qmui_height = previousHeight;
                
                // ?????????????????????????????????????????? mask???????????? NavigationBar ???????????????????????????????????? backgroundView
                CAShapeLayer *maskLayer = [CAShapeLayer layer];
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathAddRect(path, NULL, CGRectMake(0, 0, searchBarContainerView.qmui_width, previousHeight));
                maskLayer.path = path;
                searchBarContainerView.layer.mask = maskLayer;
            }
        }
    }
}

- (void)qmuisb_fixSearchResultsScrollViewContentInsetIfNeeded {
    if (!self.qmuisb_shouldFixLayoutWhenUsedAsTableHeaderView) return;
    if (self.qmui_isActive) {
        UIViewController *searchResultsController = self.qmui_searchController.searchResultsController;
        if (searchResultsController && [searchResultsController isViewLoaded]) {
            UIView *view = searchResultsController.view;
            UIScrollView *scrollView =
            [view isKindOfClass:UIScrollView.class] ? view :
            [view.subviews.firstObject isKindOfClass:UIScrollView.class] ? view.subviews.firstObject : nil;
            UIView *searchBarContainerView = self.superview;
            if (scrollView && searchBarContainerView) {
                scrollView.contentInset = UIEdgeInsetsMake(searchBarContainerView.qmui_height, 0, 0, 0);
            }
        }
    }
}

static CGSize textFieldDefaultSize;
+ (CGSize)qmuisb_textFieldDefaultSize {
    if (CGSizeIsEmpty(textFieldDefaultSize)) {
        textFieldDefaultSize = CGSizeMake(60, 28);
        // ??? iOS 11 ???????????????????????????????????????????????? 36???iOS 10 ????????????????????? 28
        if (@available(iOS 11.0, *)) {
            textFieldDefaultSize.height = 36;
        }
    }
    return textFieldDefaultSize;
}

// ?????? textField ??????????????????????????????????????? qmui_textFieldMargins ??? 0 ?????????????????????????????????????????????????????????????????? safeAreaInsets ??????
static UIEdgeInsets textFieldDefaultMargins;
+ (UIEdgeInsets)qmuisb_textFieldDefaultMargins {
    if (UIEdgeInsetsEqualToEdgeInsets(textFieldDefaultMargins, UIEdgeInsetsZero)) {
        textFieldDefaultMargins = UIEdgeInsetsMake(10, 8, 10, 8);
    }
    return textFieldDefaultMargins;
}

static CGFloat seachBarDefaultActiveHeight;
+ (CGFloat)qmuisb_seachBarDefaultActiveHeight {
    if (!seachBarDefaultActiveHeight) {
        seachBarDefaultActiveHeight = IS_NOTCHED_SCREEN ? 55 : 50;
    }
    return seachBarDefaultActiveHeight;
}

@end
