//
//  ViewController.m
//  TossGesture
//
//  Created by Paul Solt on 2/19/14.
//  Copyright (c) 2014 Paul Solt. All rights reserved.
//

#import "ViewController.h"


static const float kVelocityScale = 0.4; //.2   // Scales the velocity of the finger (higher = faster)
static const float kThrowDuration = .6; // .3  // Makes the animation last longer

static const float kVelocityThreshold = 150; // 150 // Good if you want to allow fine positional placement, not necessary for objects that always throw

@interface ViewController () {
    UIView *_blueView;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    // Add a blue view with a gesture

    _blueView = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
    _blueView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_blueView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] init];
    [panGesture addTarget:self action:@selector(handlePanGesture:)];
    [_blueView addGestureRecognizer:panGesture];

}
- (IBAction)resetButtonPressed:(id)sender {
    _blueView.transform = CGAffineTransformIdentity;
    _blueView.center = CGPointMake(200, 200);
    
    
}

- (CGFloat)magnitude:(CGPoint)theVelocity {
    CGFloat value = theVelocity.x * theVelocity.x + theVelocity.y * theVelocity.y;
    return sqrtf(value);
}



- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    
    
    if([gesture state] == UIGestureRecognizerStateBegan) {
        
        //animationCount++;
        // grab the current presentationLayerPosition and set the views current position to what it was when it was animating
        CALayer *presentationLayer = [[[gesture view] layer] presentationLayer];
        [[gesture view] setCenter:[presentationLayer position]];
        
        // NOTE: Paul 8/17/11 fixes bug with animated images when moving them
        CGFloat myAngle = [[presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue];
        [gesture view].transform = CGAffineTransformMakeRotation(myAngle);
        
        // Cancel the movement animation to remove jerky animations when grabbing a view that's moving
        [[[gesture view] layer] removeAllAnimations];
        
    }

    
    if(UIGestureRecognizerStateChanged == gesture.state) {
        NSLog(@"pan: %@ self.center: %@", gesture.view, NSStringFromCGPoint(gesture.view.center));
        
        
        CGPoint translation = [gesture translationInView:gesture.view];
        
        gesture.view.center = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:gesture.view];
        
    }
    
    UIView *myView = [gesture view];
	CGPoint translate = [gesture translationInView:[myView superview]];
    CGPoint velocity = [gesture velocityInView:[myView superview]];
    CGFloat velocityMagnitude = [self magnitude:velocity];

    
    if([gesture state] == UIGestureRecognizerStateEnded) {
        
        
        CALayer *presentationLayer = [myView.layer presentationLayer];
        CGPoint startPoint = [presentationLayer position];  // Use the last animated postion, so it doesn't jump
        
		CGPoint endPoint = gesture.view.center;  // Use the final postion after the animation
        
        if(velocityMagnitude > kVelocityThreshold) {   // Use a threshold to prevent positional slide
            endPoint.x = endPoint.x + velocity.x * kVelocityScale;
            endPoint.y = endPoint.y + velocity.y * kVelocityScale;
        }
		
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
		animation.duration = kThrowDuration;
		animation.fromValue = [NSValue valueWithCGPoint:startPoint];
		animation.toValue = [NSValue valueWithCGPoint:endPoint];
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	    [myView.layer addAnimation:animation forKey:@"position"];
        myView.layer.position = endPoint;   // Must set end position, otherwise it jumps back
        
        
        // Scale the magnitude to use as a multiplier based on velocity to use for angular rotation
        CGFloat angularMagnitude = velocityMagnitude / 600; // High velocity = more spin
        //  ALog(@"Angular Velocity: %f", angularMagnitude);
        
        if(angularMagnitude < .5) { // Set a threshold for no angular spin
            angularMagnitude = 0;
        }
        
        if(angularMagnitude > 4.0) {
            angularMagnitude = 4.0;
        }
        
        // Rotate in either direction scaled by the velocity magnitude and relative to starting angle
        CGFloat toAngle = ((((drand48()) * 2.0) - 1) * angularMagnitude) * .5;
        [UIView beginAnimations:nil context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:kThrowDuration];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        myView.transform = CGAffineTransformRotate(myView.transform, toAngle);
        [UIView commitAnimations];
        
    }

}


@end
