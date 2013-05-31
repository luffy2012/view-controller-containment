//
//  RGMapViewController.m
//  RGContainmentViewController
//
//  Created by Ricki Gregersen on 5/23/13.
//  Copyright (c) 2013 Ricki Gregersen. All rights reserved.
//

#import "RGMapViewController.h"
#import "RGMapAnnotation.h"
#import "RGAnnotationView.h"
#import "UIView+FLKAutoLayout.h"
#import <MapKit/MapKit.h>

@interface RGMapViewController ()<MKMapViewDelegate> {
    
    MKMapView *mapView;
}

@end

@implementation RGMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor greenColor]];
    
    mapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    [mapView setDelegate:self];
    [mapView setMapType:MKMapTypeHybrid];
    [self.view addSubview:mapView];    
    
    [mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mapView constrainWidthToView:self.view predicate:nil];
    [mapView constrainHeightToView:self.view predicate:nil];
    [mapView alignTopEdgeWithView:self.view predicate:nil];
    
    RGMapAnnotation *mapAnnotation = [RGMapAnnotation new];
    [mapView addAnnotation:mapAnnotation];
}

- (void) updateAnnotationLocation:(CLLocation *)location
{
    RGMapAnnotation *annotation = [mapView.annotations lastObject];
    
    [annotation setCoordinate:location.coordinate];
    [self snapToLocation:location];
    //Avoid self.currentLocation here as it will cause the KVO observer to repeatedly try and update
    _currentLocation = location;
    [self reverseGeoCodeLocation:_currentLocation];
}

- (void) snapToLocation:(CLLocation*) location
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000000.0, 1000000.0);
    [mapView setRegion:region animated:YES];
}

#pragma mark - MKMapViewDelegate

-(MKAnnotationView *)mapView:(MKMapView *) theMapView viewForAnnotation:(id)annotation{
    
    NSString *annotationIdentifier = self.annotationImagePath;
    
    if([annotation isKindOfClass:[RGMapAnnotation class]]) {
        
        RGAnnotationView *annotationView = (RGAnnotationView*)[theMapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if(!annotationView){
            annotationView=[[RGAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            annotationView.image=[UIImage imageNamed:annotationIdentifier];
            
            if (self.annotationImagePath)
                annotationView.image = [UIImage imageNamed:self.annotationImagePath];

            annotationView.draggable = YES;
            
        } else {
            
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)annotationView
didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:droppedAt.latitude longitude:droppedAt.longitude];
        
        [self snapToLocation:newLocation];
        self.currentLocation = newLocation;
        [self reverseGeoCodeLocation:self.currentLocation];   
    }
}

#pragma mark - Reverse geolocation
- (void) reverseGeoCodeLocation:(CLLocation*) location
{
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error) {
            
            NSMutableString  *placeStr = [NSMutableString string];
            
            for (CLPlacemark *p in placemarks) {
                
                if (p.name != NULL)
                    [placeStr appendFormat:@"%@ ", p.name];
                if (p.locality != NULL)
                    [placeStr appendFormat:@"%@ ", p.locality];
                if (p.country != NULL)
                    [placeStr appendFormat:@"%@ ", p.country];
                
                self.locationString = (NSString*)placeStr;
            }
        }
    }];
}

#pragma mark Antipode calculation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
