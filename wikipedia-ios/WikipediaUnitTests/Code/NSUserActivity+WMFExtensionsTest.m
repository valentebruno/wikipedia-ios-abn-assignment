#import <XCTest/XCTest.h>
#import "NSUserActivity+WMFExtensions.h"

@interface NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test : XCTestCase
@end

@implementation NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test

- (void)testURLWithoutWikipediaSchemeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testInvalidArticleURLReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testArticleURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/wiki/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString, @"https://en.wikipedia.org/wiki/Foo");
}

- (void)testExploreURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://explore"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeExplore);
}

- (void)testSavedURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://saved"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeSavedPages);
}

- (void)testSearchURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/w/index.php?search=dog"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString,
                          @"https://en.wikipedia.org/w/index.php?search=dog&title=Special:Search&fulltext=1");
}

- (void)testPlacesURLWithArticleURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?WMFArticleURL=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FAmsterdam"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertEqualObjects(activity.wmf_linkURL.absoluteString, @"https://en.wikipedia.org/wiki/Amsterdam");
    XCTAssertNil(activity.wmf_placesLatitude);
    XCTAssertNil(activity.wmf_placesLongitude);
}

- (void)testPlacesURLWithCoordinates {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=52.3676&lon=4.9041"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertEqualWithAccuracy(activity.wmf_placesLatitude.doubleValue, 52.3676, 0.0001);
    XCTAssertEqualWithAccuracy(activity.wmf_placesLongitude.doubleValue, 4.9041, 0.0001);
}

- (void)testPlacesURLWithInvalidCoordinates {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=abc&lon=4.9041"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.wmf_placesLatitude);
    XCTAssertNil(activity.wmf_placesLongitude);
}

- (void)testPlacesURLWithOutOfRangeLatitude {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=999&lon=4.9041"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity.wmf_placesLatitude);
    XCTAssertNil(activity.wmf_placesLongitude);
}

- (void)testPlacesURLWithOutOfRangeLongitude {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=52.3676&lon=999"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity.wmf_placesLatitude);
    XCTAssertNil(activity.wmf_placesLongitude);
}

- (void)testPlacesURLWithLatitudeLongitudeParams {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?latitude=52.3676&longitude=4.9041"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqualWithAccuracy(activity.wmf_placesLatitude.doubleValue, 52.3676, 0.0001);
    XCTAssertEqualWithAccuracy(activity.wmf_placesLongitude.doubleValue, 4.9041, 0.0001);
}

- (void)testPlacesURLWithLngParam {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=52.3676&lng=4.9041"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqualWithAccuracy(activity.wmf_placesLatitude.doubleValue, 52.3676, 0.0001);
    XCTAssertEqualWithAccuracy(activity.wmf_placesLongitude.doubleValue, 4.9041, 0.0001);
}

- (void)testPlacesURLWithMissingLongitude {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=52.3676"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity.wmf_placesLatitude);
    XCTAssertNil(activity.wmf_placesLongitude);
}

- (void)testPlacesURLWithNegativeCoordinates {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?lat=-33.8688&lon=-70.6693"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqualWithAccuracy(activity.wmf_placesLatitude.doubleValue, -33.8688, 0.0001);
    XCTAssertEqualWithAccuracy(activity.wmf_placesLongitude.doubleValue, -70.6693, 0.0001);
}

@end
