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
#import "MemoryElement.h"

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
// This action includes updating growth & survival memory,
// decision of juveniles of whether to become presmolts, and
// decision by juveniles whether to become prespawners. 
//
////////////////////////////////////////////////////////////////////////////////////////
- selectLifeHistory
{

	double meanGrowth;   // over memory period
	double meanSurvival; // over memory period
	id aMemory;          // Did not work to declare as <MemoryElement>
	id <Averager> theGrowthAverager; // Did not work to use one averager for growth & survival
	id <Averager> theSurvivalAverager; // Did not work to use one averager for growth & survival
	double anadromyFitness;
	double residenceFitness;
	int residenceTimeHorizon;
	time_t now;
	
	if(lifestageSymbol != [model getJuvenileLifestageSymbol])
	{
	 return self;  // Only juveniles use this method.
	}
	 
	// fprintf(stdout, "OMykiss >>>> selectLifeHistory >>>> Before create memory\n");
	// fflush(0);

	// Update memory list with today's growth & survival
	aMemory = [MemoryElement createBegin: [model getModelZone]
			withGrowth: netEnergyForBestCell/(fishParams->fishEnergyDensity)
			andSurvival: nonStarvSurvival];
	aMemory = [aMemory createEnd];

	// fprintf(stdout, "OMykiss >>>> After new memory; today's growth: %f, today's survival: %f\n", 
	// [aMemory getGrowthValue], [aMemory getSurvivalValue]);
	
	// fprintf(stdout, "OMykiss >>>> selectLifeHistory >>>> Before add memory\n");
	// fflush(0);

	[memoryList addFirst: aMemory];

	if([memoryList getCount] > (fishParams->fishMemoryListLength))
	{
		[memoryList removeLast];
		if([memoryList getCount] != (fishParams->fishMemoryListLength))
		{
			fprintf(stderr, "ERROR: OMykiss >>>> selectLifeHistory >>>> Memory list length is: %d\n", 
			[memoryList getCount]);
			fflush(0);
			exit(1);
		}
	}

			// fprintf(stdout, "OMykiss >>>> selectLifeHistory >>>> Memory list length is: %d\n", 
			// [memoryList getCount]);
			// fflush(0);
	
	// Juveniles do not make life history decisions until their age in days
	// exceeds the parameter fishMemoryListLength
	if([memoryList getCount] < (fishParams->fishMemoryListLength))
	{
		return self;
	}
	// Juveniles do not make life history decisions after their age in years
	// exceeds 2
	if(age >= 2)
	{
		return self;
	}
	
	// Now update means over memory
	// First create the averagers if they doesn't exist.
	// (Does not work to use one averager for both selectors)

	theGrowthAverager = [model getMemoryGrowthAverager];
	if(theGrowthAverager == nil)
	{
		theGrowthAverager = [Averager createBegin: [model getModelZone]]; 
		[theGrowthAverager setCollection: memoryList];
		[theGrowthAverager setProbedSelector: M(getGrowthValue)];
		theGrowthAverager = [theGrowthAverager createEnd];
	}

	theSurvivalAverager = [model getMemorySurvivalAverager];
	if(theSurvivalAverager == nil)
	{
		theSurvivalAverager = [Averager createBegin: [model getModelZone]]; 
		[theSurvivalAverager setCollection: memoryList];
		[theSurvivalAverager setProbedSelector: M(getSurvivalValue)];
		theSurvivalAverager = [theSurvivalAverager createEnd];
	}
	
	// fprintf(stdout, "OMykiss >>>> selectLifeHistory >>>> Before Averager set collection\n");
	// fflush(0);

	// Update averagers and get means.
	[theGrowthAverager setCollection: memoryList];
	[theGrowthAverager update];
	meanGrowth = [theGrowthAverager getAverage];
	[theSurvivalAverager setCollection: memoryList];
	[theSurvivalAverager update];
	meanSurvival = [theSurvivalAverager getAverage];

	// fprintf(stdout, "OMykiss >>>> After update; Memory length: %d, meanGrowth: %f, meanSurvival: %f\n", 
	// [memoryList getCount], meanGrowth, meanSurvival);

	//
	// Juvenile decides to become presmolt if its anadromy fitness
	// exceeds residence fitness
	//
	// First, calculate residence time horizon
	//
	now = [self getCurrentTimeT];
	
	if(age == 0)
	{
		residenceTimeHorizon = 365 + [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
	}
	else   // this should only happen for age 1
	{
		if([timeManager isTimeT: now betweenMMDD: "1/1" 
			andMMDD: fishParams->fishSpawnStartDate])
		{
			residenceTimeHorizon = 365 + [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
		}
		else
		{
			residenceTimeHorizon = [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
		}
		
	}
	
	anadromyFitness = [self anadromyFitnessWithGrowth: meanGrowth
						andSurvival: meanSurvival
						andTimeHorizon: fishParams->fishSmoltDelay];

	residenceFitness = [self residenceFitnessWithGrowth: meanGrowth
						andSurvival: meanSurvival
						andTimeHorizon: residenceTimeHorizon];
	
	if(anadromyFitness > residenceFitness)
	{
		lifestageSymbol = [model getPresmoltLifestageSymbol];
	}

	return self;
}

///////////////////////////////////////////////////////////////////////
//
// anadromyFitnessWithGrowth:
//
///////////////////////////////////////////////////////////////////////
- (double) anadromyFitnessWithGrowth: (double) aGrowth
						andSurvival: (double) aSurvival
						andTimeHorizon: (int) someDays
{
	double nonStarveSurvival;
	double starvSurvival;
	double oceanSurvival = 1.0;
	double expectedOffspring = 999;
	
	double newWeight;
	double newLength;
	double newCondition;
	double dailyStarvSurvival;
	double Kt, KT, a, b;

	if(myCell == nil)
	{
		fprintf(stderr, "ERROR: OMykiss >>>> anadromyFitnessWithGrowth >>>> fish cell is nil\n");
		fflush(0);
		exit(1);
	}

	
	// First, calculate non-starvation survival over time horizon
	nonStarveSurvival = pow(aSurvival,someDays);
	
	// Second, calculate starvation survival over time horizon
	// This duplicates some stuff in methods called by expectedMaturityAt:
	newWeight = fishWeight + (aGrowth * someDays);
	if(newWeight < 0.0) {newWeight = 0.0;}
	newLength = [self getLengthForNewWeight: newWeight];
	newCondition = [self getConditionForWeight: newWeight andLength: newLength];
	
	if(fabs(fishCondition - newCondition) < 0.001) 
	{
		[myCell updateFishSurvivalProbFor: self];
		dailyStarvSurvival = [myCell getStarvSurvivalFor: self];
	}
	else 
	{
		a = starvPa; 
		b = starvPb; 
		Kt = fishCondition;  //current fish condition
		KT = newCondition;
		dailyStarvSurvival =  (1/a)*(log((1+exp(a*KT+b))/(1+exp(a*Kt+b))))/(KT-Kt); 
	}  

	if(isnan(dailyStarvSurvival) || isinf(dailyStarvSurvival))
	{
		fprintf(stderr, "ERROR: OMykiss >>>> anadromyFitnessWithGrowth >>>> dailyStarvSurvival = %f\n", dailyStarvSurvival);
		fflush(0);
		exit(1);
	}

	starvSurvival = pow(dailyStarvSurvival,someDays);
	
	// Third, calculate expected ocean survival at end of time horizon
	oceanSurvival = fishParams->fishOceanSurvMax
		* [oceanSurvivalLogistic evaluateFor: newLength];
	
	// Finally, calculate expected offspring from sex
	if(sex == Female) {expectedOffspring = fishParams->fishExpectedOffspringOceanFemale;}
	else
	{
	 if(sex == Male) {expectedOffspring = fishParams->fishExpectedOffspringOceanMale;}
	 else
	 {
		fprintf(stderr, "ERROR: OMykiss >>>> anadromyFitnessWithGrowth >>>> sex not set\n");
		fflush(0);
		exit(1);
	 }
	}

	fprintf(stdout, "OMykiss anadromyFitnessWithGrowth nonStarv: %f starv: %f ocean: %f offspring: %f\n", nonStarveSurvival, starvSurvival, oceanSurvival, expectedOffspring);
	
	return nonStarveSurvival * starvSurvival * oceanSurvival * expectedOffspring;
}

///////////////////////////////////////////////////////////////////////
//
// residenceFitnessWithGrowth:
//
///////////////////////////////////////////////////////////////////////
- (double) residenceFitnessWithGrowth: (double) aGrowth
						andSurvival: (double) aSurvival
						andTimeHorizon: (int) someDays
{
	double nonStarveSurvival;
	double starvSurvival;
	double expectedOffspring = 999;
	
	double newWeight;
	double newLength;
	double newCondition;
	double dailyStarvSurvival;
	double Kt, KT, a, b;

	if(myCell == nil)
	{
		fprintf(stderr, "ERROR: OMykiss >>>> residenceFitnessWithGrowth >>>> fish cell is nil\n");
		fflush(0);
		exit(1);
	}

	
	// First, calculate non-starvation survival over time horizon
	nonStarveSurvival = pow(aSurvival,someDays);
	
	// Second, calculate starvation survival over time horizon
	// This duplicates some stuff in methods called by expectedMaturityAt:
	newWeight = fishWeight + (aGrowth * someDays);
	if(newWeight < 0.0) {newWeight = 0.0;}
	newLength = [self getLengthForNewWeight: newWeight];
	newCondition = [self getConditionForWeight: newWeight andLength: newLength];
	
	if(fabs(fishCondition - newCondition) < 0.001) 
	{
		[myCell updateFishSurvivalProbFor: self];
		dailyStarvSurvival = [myCell getStarvSurvivalFor: self];
	}
	else 
	{
		a = starvPa; 
		b = starvPb; 
		Kt = fishCondition;  //current fish condition
		KT = newCondition;
		dailyStarvSurvival =  (1/a)*(log((1+exp(a*KT+b))/(1+exp(a*Kt+b))))/(KT-Kt); 
	}  

	if(isnan(dailyStarvSurvival) || isinf(dailyStarvSurvival))
	{
		fprintf(stderr, "ERROR: OMykiss >>>> residenceFitnessWithGrowth >>>> dailyStarvSurvival = %f\n", dailyStarvSurvival);
		fflush(0);
		exit(1);
	}

	starvSurvival = pow(dailyStarvSurvival,someDays);
	
	// Third, calculate expected offspring from size
	expectedOffspring = (fishParams->fishFecundParamA) *
		pow(newLength,fishParams->fishFecundParamB);

	fprintf(stdout, "OMykiss residenceFitnessWithGrowth timeHor: %d nonStarv: %f starv: %f offspring: %f\n", someDays, nonStarveSurvival, starvSurvival, expectedOffspring);
	
	return nonStarveSurvival * starvSurvival * expectedOffspring;
}


@end
