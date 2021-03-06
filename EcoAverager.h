/*
EcoSwarm library for individual-based modeling, last revised April 2013.
Developed and maintained by Steve Railsback, Lang, Railsback & Associates, 
Steve@LangRailsback.com; Colin Sheppard, critter@stanfordalumni.org; and
Steve Jackson, Jackson Scientific Computing, McKinleyville, California.
Development sponsored by US Bureau of Reclamation under the 
Central Valley Project Improvement Act, EPRI, USEPA, USFWS,
USDA Forest Service, and others.
Copyright (C) 2011 Lang, Railsback & Associates.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see file LICENSE); if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*/



//#import <analysis.h> // Averager
#import "EcoAveragerP.h" // Averager
#import <objectbase/MessageProbe.h>

// Average object: calculates a few basic statistics given a collection of 
// objects to poll and a selector with which to poll them.

@interface EcoAverager: MessageProbe <EcoAverager>
{
  double total, totalSquared; 
  double max, min;
  unsigned count, totalCount;
  id target;
  BOOL isList;

  unsigned maWidth;
  double maTotal;
  double maTotalSquared;
  double *maData;

  id (*nextImp) (id, SEL);
  id (*getLocImp) (id, SEL);
  double (*callImp) (id, SEL, id);
  void (*addImp) (id, SEL, double);
}

- setCollection: aCollection;
- setWidth: (unsigned)width;
- createEnd;		

- (void)update;					  // update the average.
- (double)getAverage;
- (double)getMovingAverage;
- (double)getVariance;
- (double)getMovingVariance;
- (double)getStdDev;
- (double)getMovingStdDev;
- (double)getTotal;
- (double)getMax;
- (double)getMin;
- (unsigned)getCount;
@end

