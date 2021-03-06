//
//  Segment-AmplitudeTests.m
//  Segment-AmplitudeTests
//
//  Created by Prateek Srivastava on 11/10/2015.
//  Copyright (c) 2015 Prateek Srivastava. All rights reserved.
//

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs);


describe(@"SEGAmplitudeIntegrationFactory", ^{
    it(@"factory creates integration with basic settings", ^{
        SEGAmplitudeIntegration *integration = [[SEGAmplitudeIntegrationFactory instance] createWithSettings:@{
            @"apiKey" : @"1234"
        } forAnalytics:nil];
        expect(integration.settings).to.equal(@{ @"apiKey" : @"1234" });

    });

    it(@"factory creates integration with trackSessionEvents", ^{
        SEGAmplitudeIntegration *integration = [[SEGAmplitudeIntegrationFactory instance] createWithSettings:@{
            @"apiKey" : @"1234",
            @"trackSessionEvents" : @true
        } forAnalytics:nil];
        expect(integration.settings).to.equal(@{ @"apiKey" : @"1234",
                                                 @"trackSessionEvents" : @true });
    });
});

describe(@"SEGAmplitudeIntegration", ^{

    __block Amplitude *amplitude;
    __block SEGAmplitudeIntegration *integration;
    __block AMPRevenue *amprevenue;
    __block AMPIdentify *identify;

    beforeEach(^{
        amplitude = mock([Amplitude class]);
        amprevenue = mock([AMPRevenue class]);
        identify = mock([AMPIdentify class]);
        integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{} andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];
    });

    describe(@"Identify", ^{

        it(@"identify without traits", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"traitsToIncrement" : [NSNull null],
                                                                               @"traitsToSetOnce" : [NSNull null] }
                                                               andAmplitude:amplitude
                                                              andAmpRevenue:amprevenue
                                                             andAmpIdentify:identify];
            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"1111" anonymousId:nil traits:@{} context:@{} integrations:@{}];

            [integration identify:payload];
            [verify(amplitude) setUserId:@"1111"];
        });

        it(@"identify with traits", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"traitsToIncrement" : @[],
                                                                               @"traitsToSetOnce" : @[] }
                                                               andAmplitude:amplitude
                                                              andAmpRevenue:amprevenue
                                                             andAmpIdentify:identify];
            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"7891" anonymousId:nil traits:@{
                @"name" : @"George Costanza",
                @"gender" : @"male",
                @"quality" : @"unstable",
                @"age" : @47
            } context:@{}
                integrations:@{}];
            [integration identify:payload];
            [verify(amplitude) setUserProperties:payload.traits];
        });

        it(@"identify with groups", ^{
            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"7891" anonymousId:nil traits:@{
                @"name" : @"Elaine Marie Benes",
                @"gender" : @"female",
                @"quality" : @"assertiveness",
                @"age" : @36
            } context:@{} integrations:@{ @"Amplitude" : @{
                @"groups" : @{
                    @"jobs" : @[ @"Pendant Publishing" ]
                }
            } }];
            [integration identify:payload];
            [verify(amplitude) setGroup:@"jobs" groupName:@[ @"Pendant Publishing" ]];
        });

        it(@"increments identify trait", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"traitsToIncrement" : @[ @"karma", @"store_credit" ] } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"3290842" anonymousId:nil traits:@{ @"karma" : @0.23,
                                                                                                                          @"store_credit" : @20,
                                                                                                                          @"gender" : @"female" }
                context:@{}
                integrations:@{}];

            [integration identify:payload];
            [verify(amplitude) identify:[identify add:@"karma" value:@0.23]];
            [verify(amplitude) identify:[identify add:@"store_credit" value:@20]];
            [verify(amplitude) identify:[identify set:@"gender" value:@"female"]];
        });

        it(@"sets identify trait once", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"traitsToSetOnce" : @[ @"sign_up_date" ] } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"3290842" anonymousId:nil traits:@{ @"sign_up_date" : @"2015-08-24",
                                                                                                                          @"city" : @"los angeles" }
                context:@{}
                integrations:@{}];

            [integration identify:payload];
            [verify(amplitude) identify:[identify setOnce:@"sign_up_date" value:@"2015-08-24"]];
            [verify(amplitude) identify:[identify set:@"city" value:@"los angeles"]];
        });

        it(@"sets identify trait once and increments trait", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"traitsToSetOnce" : @[ @"birthdate" ],
                                                                               @"traitsToIncrement" : @[ @"age" ] }
                                                               andAmplitude:amplitude
                                                              andAmpRevenue:amprevenue
                                                             andAmpIdentify:identify];

            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"3290842" anonymousId:nil traits:@{ @"address" : @{
                @"street" : @"California st",
                @"city" : @"San Francisco"
            },
                                                                                                                          @"birthdate" : @"1989-07-10",
                                                                                                                          @"name" : @"ladan",
                                                                                                                          @"age" : @28 }
                context:@{}
                integrations:@{}];

            [integration identify:payload];
            [verify(amplitude) identify:[identify setOnce:@"birthdate" value:@"1989-07-10"]];
            [verify(amplitude) identify:[identify add:@"age" value:@28]];
            [verify(amplitude) identify:[identify set:@"name" value:@"ladan"]];
            [verify(amplitude) identify:[identify set:@"address" value:@{
                @"street" : @"California st",
                @"city" : @"San Francisco"
            }]];
        });

    });

    describe(@"Screen", ^{
        it(@"does not call screen if trackAllPages = false", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackAllPages" : @false } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Shirts" properties:@{} context:@{} integrations:@{}];
            [integration screen:payload];
            [verifyCount(amplitude, never()) logEvent:@"Viewed Shirts Screen" withEventProperties:@{}];
        });

        it(@"trackAllPages", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackAllPages" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Shirts" properties:@{} context:@{} integrations:@{}];
            [integration screen:payload];
            [verify(amplitude) logEvent:@"Viewed Shirts Screen" withEventProperties:@{} withGroups:nil outOfSession:false];
        });

        it(@"trackAllPagesV2", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackAllPagesV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Shirts" properties:@{ @"url" : @"seinfeld.wikia.com/wiki/The_Puffy_Shirt",
                                                                                                       @"Feed Type" : @"private" }
                context:@{}
                integrations:@{}];
            [integration screen:payload];
            [verify(amplitude) logEvent:@"Loaded a Screen" withEventProperties:@{ @"name" : @"Shirts",
                                                                                  @"url" : @"seinfeld.wikia.com/wiki/The_Puffy_Shirt",
                                                                                  @"Feed Type" : @"private" } withGroups:nil outOfSession:false];
        });
    
        it(@"does not call screen if trackNamedPages = false", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackNamedPages" : @false } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Shirts" properties:@{} context:@{} integrations:@{}];
            [integration screen:payload];
            [verifyCount(amplitude, never()) logEvent:@"Viewed Shirts Screen" withEventProperties:@{}];
        });
    
        it(@"does not call screen if trackNamedPages = true, but screen has no name", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackAllPages" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"" properties:@{} context:@{} integrations:@{}];
            [integration screen:payload];
            
            [verifyCount(amplitude, never()) logEvent:@"Viewed  Screen" withEventProperties:@{}];
        });
    
    
        it(@"trackNamedPages", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"trackNamedPages" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"Shirts" properties:@{} context:@{} integrations:@{}];
            [integration screen:payload];
            [verify(amplitude) logEvent:@"Viewed Shirts Screen" withEventProperties:@{} withGroups:nil outOfSession:false];
        });

    });

    describe(@"Group", ^{
        it(@"sets groupId", ^{
            SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:@"322" traits:@{} context:@{} integrations:@{}];
            [integration group:payload];
            [verify(amplitude) setGroup:@"322" groupName:@"[Segment] Group"];
        });

        it(@"settings.groupTypeValue and settings.groupTypeTrait", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"groupTypeValue" : @"company",
                                                                               @"groupTypeTrait" : @"industry" }
                                                               andAmplitude:amplitude
                                                              andAmpRevenue:amprevenue
                                                             andAmpIdentify:identify];
            SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:@"32423084" traits:@{
                @"company" : @"Segment",
                @"industry" : @"Technology"
            }
                context:@{}
                integrations:@{}];
            [integration group:payload];
            [verify(amplitude) setGroup:@"Segment" groupName:@"Technology"];
        });

        it(@"sets group name with traits.name", ^{
            SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:@"12342" traits:@{ @"name" : @"Segment" } context:@{} integrations:@{}];
            [integration group:payload];
            [verify(amplitude) setGroup:@"12342" groupName:@"Segment"];
        });
    });

    describe(@"Flush", ^{
        it(@"calls uploadEvents", ^{
            [integration flush];
            [verify(amplitude) uploadEvents];
        });
    });

    describe(@"Reset", ^{
        it(@"calls regenerateDeviceId", ^{
            [integration reset];
            [verify(amplitude) setUserId:nil];
            [verify(amplitude) regenerateDeviceId];
        });
    });

    describe(@"Track", ^{
        it(@"tracks a basic event without props", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Email Sent" properties:@{} context:@{} integrations:@{}];

            [integration track:payload];
            [verify(amplitude) logEvent:@"Email Sent" withEventProperties:@{} withGroups:nil outOfSession:false];
        });

        it(@"tracks a basic event with props", ^{
            NSDictionary *props = @{
                @"Color" : @"White",
                @"Type" : @"like the pirates used to wear"
            };
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Viewed Puffy Shirt"
                properties:props
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [verify(amplitude) logEvent:@"Viewed Puffy Shirt" withEventProperties:props withGroups:nil outOfSession:false];

        });

        it(@"tracks a basic event with groups", ^{
            NSDictionary *props = @{
                @"url" : @"seinfeld.wikia.com/wiki/The_Puffy_Shirt"
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Sent Product Link" properties:props context:@{} integrations:@{ @"Amplitude" : @{@"groups" : @{@"jobs" : @[ @"Pendant Publishing" ]}} }];
            [integration track:payload];
            [verify(amplitude) logEvent:@"Sent Product Link" withEventProperties:props withGroups:@{ @"jobs" : @[ @"Pendant Publishing" ] } outOfSession:false];
        });

        it(@"doesn't track group if not NSDictionary", ^{
            NSDictionary *props = @{
                @"url" : @"seinfeld.wikia.com/wiki/The_Puffy_Shirt"
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Sent Product Link" properties:props context:@{} integrations:@{ @"Amplitude" : @{@"groups" : @"jobs"} }];
            [integration track:payload];
            [verify(amplitude) logEvent:@"Sent Product Link" withEventProperties:props withGroups:nil outOfSession:false];
        });

        it(@"tracks an event with groups and outOfSession", ^{
            NSDictionary *props = @{
                @"order_number" : @34294
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Delivered" properties:props context:@{} integrations:@{ @"Amplitude" : @{@"groups" : @{@"Buroughs" : @[ @"Brooklyn", @"Manhattan" ]}, @"outOfSession" : @YES} }];
            [integration track:payload];
            [verify(amplitude) logEvent:@"Order Delivered" withEventProperties:props withGroups:@{ @"Buroughs" : @[ @"Brooklyn", @"Manhattan" ] } outOfSession:true];
        });

        it(@"tracks an event with groups and outOfSession", ^{
            NSDictionary *props = @{
                @"reminder" : @"drink water"
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Reminder Sent" properties:props context:@{} integrations:@{ @"Amplitude" : @{@"outOfSession" : @YES} }];
            [integration track:payload];
            [verify(amplitude) logEvent:@"Reminder Sent" withEventProperties:props withGroups:nil outOfSession:true];
        });


        it(@"tracks Order Completed with revenue if both total and revenue are present", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"useLogRevenueV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            NSDictionary *props = @{
                @"checkout_id" : @"9bcf000000000000",
                @"order_id" : @"50314b8e",
                @"affiliation" : @"App Store",
                @"total" : @30.45,
                @"shipping" : @5.05,
                @"tax" : @1.20,
                @"currency" : @"USD",
                @"category" : @"Games",
                @"revenue" : @8,
                @"products" : @{
                    @"product_id" : @"2013294",
                    @"category" : @"Games",
                    @"name" : @"Monopoly: 3rd Edition",
                    @"brand" : @"Hasbros",
                    @"price" : @"21.99",
                    @"quantity" : @"1"
                }
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:props context:@{}
                integrations:@{}];

            [integration track:payload];
            [[verify(amprevenue) setPrice:@8] setQuantity:1];
            [verify(amprevenue) setEventProperties:props];
            [verify(amplitude) logRevenueV2:amprevenue];
        });

        it(@"tracks Order Completed with total if revenue is not present", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"useLogRevenueV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            NSDictionary *props = @{
                @"checkout_id" : @"9bcf000000000000",
                @"order_id" : @"50314b8e",
                @"affiliation" : @"App Store",
                @"total" : @30.45,
                @"shipping" : @5.05,
                @"tax" : @1.20,
                @"currency" : @"USD",
                @"category" : @"Games",
                @"products" : @{
                    @"product_id" : @"2013294",
                    @"category" : @"Games",
                    @"name" : @"Monopoly: 3rd Edition",
                    @"brand" : @"Hasbros",
                    @"price" : @"21.99",
                    @"quantity" : @"1"
                }
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:props
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [[verify(amprevenue) setPrice:@30.45] setQuantity:1];
            [verify(amprevenue) setEventProperties:props];
            [verify(amplitude) logRevenueV2:amprevenue];
        });

        it(@"tracks Order Completed with revenue of type String", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"useLogRevenueV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            NSDictionary *props = @{
                @"checkout_id" : @"9bcf000000000000",
                @"order_id" : @"50314b8e",
                @"affiliation" : @"App Store",
                @"total" : @30.45,
                @"shipping" : @5.05,
                @"tax" : @1.20,
                @"currency" : @"USD",
                @"category" : @"Games",
                @"revenue" : @"8",
                @"products" : @{
                    @"product_id" : @"2013294",
                    @"category" : @"Games",
                    @"name" : @"Monopoly: 3rd Edition",
                    @"brand" : @"Hasbros",
                    @"price" : @"21.99",
                    @"quantity" : @"1"
                }
            };

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:props context:@{}
                integrations:@{}];

            [integration track:payload];
            [[verify(amprevenue) setPrice:@8] setQuantity:1];
            [verify(amprevenue) setEventProperties:props];
            [verify(amplitude) logRevenueV2:amprevenue];
        });

        // NOTE: This is against our spec. We do not have a v1/v2 ECommerce event that sends both revenue and price/quantity as a tope level property
        it(@"tracks with top level price and quantity", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"useLogRevenueV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Viewed Product" properties:@{
                @"revenue" : @20.99,
                @"id" : @"507f1f77bcf86cd799439011",
                @"sku" : @"G-32",
                @"name" : @"Monopoly: 3rd Edition",
                @"price" : @18.9,
                @"category" : @"Games",
                @"quantity" : @"1"
            }
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [[verify(amprevenue) setPrice:@18.9] setQuantity:1];
            [verify(amplitude) logRevenueV2:amprevenue];
        });

        it(@"tracks Amplitude ecommerce fields", ^{
            integration = [[SEGAmplitudeIntegration alloc] initWithSettings:@{ @"useLogRevenueV2" : @true } andAmplitude:amplitude andAmpRevenue:amprevenue andAmpIdentify:identify];

            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Viewed Product" properties:@{
                @"revenue" : @20.00,
                @"product_id" : @"507f1f77bcf86cd799439011",
                @"receipt" : @"172038",
                @"revenue_type" : @"Sales",
                @"price" : @18.9,
                @"category" : @"Games"
            }
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [[verify(amprevenue) setPrice:@18.9] setQuantity:1];
            [verify(amprevenue) setProductIdentifier:@"507f1f77bcf86cd799439011"];
            [verify(amprevenue) setReceipt:@"172038"];
            [verify(amprevenue) setRevenueType:@"Sales"];
            [verify(amplitude) logRevenueV2:amprevenue];
        });

        it(@"fallsback to logRevenue v1", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Viewed Product" properties:@{
                @"revenue" : @20.00,
                @"product_id" : @"507f1f77bcf86cd799439011",
                @"receipt" : @"172038",
                @"revenue_type" : @"Sales",
                @"price" : @18.9,
                @"category" : @"Games",
                @"quantity" : @4
            }
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [verify(amplitude) logRevenue:@"507f1f77bcf86cd799439011"
                                 quantity:4
                                    price:@20.00
                                  receipt:@"172038"];

        });

        it(@"fallsback to logRevenue v1 with default values", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Viewed Product" properties:@{
                @"revenue" : @20.00
            }
                context:@{}
                integrations:@{}];

            [integration track:payload];
            [verify(amplitude) logRevenue:nil
                                 quantity:1
                                    price:@20.00
                                  receipt:nil];

        });

    });

});

SpecEnd
