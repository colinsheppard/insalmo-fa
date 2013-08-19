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




#import "globals.h"
#import "OMykiss.h"

@implementation OMykiss

+ createBegin: aZone 
{
   return [super createBegin: aZone];
}




///////////////////////////////////////////////////////////////////////////////
//
// compareArrivalTime
// Needed by QSort in TroutModelSwarm method: createSpawners
//
///////////////////////////////////////////////////////////////////////////////
- (int) compareArrivalTime: aSpawner 
//- (int) compare: aSpawner 
{
  double oFishArriveTime = [aSpawner getArrivalTime];

  if(arrivalTime > oFishArriveTime)
  {
     return 1;
  }
  else if(arrivalTime == oFishArriveTime)
  {
     return 0;
  }
  else
  {
     return -1;
  }
}

////////////////////////////////////////////////
//
// drop
//
///////////////////////////////////////////////
- (void) drop
{
     [super drop];
}

//////////////////////////////////////////////////////////////////////
//
// Move 
//
// move is the second action taken by fish in their daily routine 
//
// inSALMO-FA: OMykiss class has its own version of this method
//////////////////////////////////////////////////////////////////////
- move 
{
       //fprintf(stdout, "Trout >>>> move >>>> BEGIN\n");
       //fflush(0);
   //
   // calcMaxMoveDistance sets the ivar
   // maxMoveDistance.
   //
   [self calcMaxMoveDistance];

   if(isSpawner == YES)
   {

     if(spawnedThisSeason == YES)
     {
       //
       // Spawners do not move once they have spawned, to guard their redd.
       // The non-moving spawners still do grow and die, so they need all the
       // variables set in moving to a cell
       //

       [self moveToBestDest: myCell];

       //fprintf(stdout, "Trout >>>> move >>>> depthLengthRatioForCell = %f\n",depthLengthRatioForCell);
     } // if spawned this seasons

     else
     {
       //
       // Spawners who have not yet spawned move, but to minimize risk and cannot
       // move out of their reach. Methods to calculate drift and search intake
       // return zero if "isSpawner" is YES.
       //
       [self moveInReachToMaximizeSurvival];
     } // else - spawner who did not spawn yet
   }   // if isSpawner

   else  // isSpawner != YES
   {

     if(spawnedThisSeason != NO)
     {
      fprintf(stderr, "ERROR: OMykiss >>>> Move >>>> isSpawner = NO and spawnedThisSeason != NO\n");
      fflush(0);
      exit(1);
     }

	 if(lifestageSymbol == [model getJuvenileLifestageSymbol])
     {
         [self moveToMaximizeExpectedMaturity];
     }

     else  // "else"s are necessary to keep a fish from moving twice if they change life stage
	 if(lifestageSymbol == [model getPresmoltLifestageSymbol])
     {
         [self moveAsPresmolt];
     }

	else
	if(lifestageSymbol == [model getSmoltLifestageSymbol])
     {
         [self moveAsSmolt];
     }

	 else
	if(lifestageSymbol == [model getPrespawnLifestageSymbol])
     {
         [self moveAsPrespawner];
     }

	 else
     {
      fprintf(stderr, "ERROR: OMykiss >>>> Move >>>> Fish with illegal lifestage: %s\n", 
		[lifestageSymbol getName]);
      fflush(0);
      exit(1);
     }

    }  // else isSpawner != YES

   return self;

}

//////////////////////////////////////////////////////////////////////
//
// moveAsPresmolt
//
//////////////////////////////////////////////////////////////////////
- moveAsPresmolt              // Stub for now
{
         [self moveToMaximizeExpectedMaturity];

		 return self;
}

//////////////////////////////////////////////////////////////////////
//
// moveAsSmolt
//
//////////////////////////////////////////////////////////////////////
- moveAsSmolt              // Stub for now
{
         [self moveToMaximizeExpectedMaturity];

		 return self;
}

//////////////////////////////////////////////////////////////////////
//
// moveAsPrespawner
//
//////////////////////////////////////////////////////////////////////
- moveAsPrespawner              // Stub for now
{
         [self moveToMaximizeExpectedMaturity];

		 return self;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// selectLifeHistory
// inSALMO-FA -- the fifth fish action  
//
////////////////////////////////////////////////////////////////////////////////////////
- selectLifeHistory
{
  return self;  // stub for now
}


@end
