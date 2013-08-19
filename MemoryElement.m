/*
inSALMO individual-based salmon model, Version 1.2, April 2013.
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

//
// MemoryElement contains a fish's memory of growth and survival
// for one time step. Developed for inSALMO-FA.
//

#import "MemoryElement.h"
#import <stdlib.h>


@implementation MemoryElement

+ createBegin: aZone
   withGrowth: (double) aGrowth
  andSurvival: (double) aSurvival
{

	 
     MemoryElement* memoryElement = [super createBegin: aZone];

     //fprintf(stdout, "memoryElement >>>> createBegin >>>> BEGIN\n");
     //fflush(0);

     memoryElement->survivalValue = aSurvival;
     memoryElement->growthValue = aGrowth;
  
     //fprintf(stdout, "memoryElement >>>> createBegin >>>> END\n");
     //fflush(0);

     return memoryElement;
}


///////////////////////////////////////////////
//
//  createEnd
//
//////////////////////////////////////////////
- createEnd
{
    if((survivalValue <= 0.0) || (survivalValue > 1.0))   
    {
         fprintf(stderr, "ERROR: MemoryElement >>>> createEnd >>>> survival value is: %f\n",survivalValue);
         fflush(0);
         exit(1);
    }

    return [super createEnd];
}


////////////////////////////////////////
//
// getGrowthValue
//
////////////////////////////////////////
- (double) getGrowthValue
{
    return growthValue;
}



/////////////////////////////////////////
//
// getSurvivalValue
//
/////////////////////////////////////////
- (double) getSurvivalValue
{
    return survivalValue;
}


////////////////////////////////////////////
//
// drop
//
///////////////////////////////////////////
- (void) drop
{
     [super drop];
}

@end

