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
	OMykiss * newOMykiss;
	
	newOMykiss = [super createBegin: aZone];
	
	newOMykiss->smoltTime = (time_t) 0; // Initialize a variable unique to OMykiss subclass
	
	return newOMykiss;
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
       //fprintf(stdout, "OMykiss >>>> move >>>> BEGIN\n");
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

       //fprintf(stdout, "OMykiss >>>> move >>>> depthLengthRatioForCell = %f\n",depthLengthRatioForCell);
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
	 // Juveniles cannot outmigrate after fishMemoryListLength number of days
     {
		if([memoryList getCount] < fishParams->fishMemoryListLength) // cannot be "<=" !!
		{
			[self moveToMaximizeExpectedMaturity];
		}
		else
		{
			// This existing method does what we want despite its name
			[self moveInReachToMaximizeSurvival]; 
		}
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
// modified from moveToMaximizeMaturity
// This is also used by smolts after they move down into a new reach
//
//////////////////////////////////////////////////////////////////////
- moveAsPresmolt
{
  id <ListIndex> destNdx;
  FishCell *destCell=nil;
  FishCell *bestDest=nil;
  double bestPresmoltFitness=0.0;
  double presmoltFitnessHere=0.0;
  double presmoltFitnessAtDest=0.0;

  //double outMigFuncValue = [juveOutMigLogistic evaluateFor: fishLength];

  //fprintf(stdout, "Trout >>>> moveAsPresmolt >>>> BEGIN >>>> fish = %p\n", self);
  //fprintf(stdout, "Trout >>>> moveAsPresmolt >>>> outMigFuncValue = %f\n", outMigFuncValue);
  //fflush(0);
  //exit(0);

  if(myCell == nil) 
  {
    fprintf(stderr, "WARNING: Trout >>>> moveAsPresmolt >>>> Fish 0x%p has no Cell context.\n", self);
    fflush(0);
    return self;
  }

  //
  // Calculate the variables that depend only on the reach that a fish is in.
  //  (can't do this because cells may be in multiple reaches, with different 
  //  temperature and turbidity. Moved to presmoltFitnessAt:
  // temporaryTemperature = [myCell getTemperature];
  // standardResp    = [self calcStandardRespirationAt: myCell];
  // cMax            = [self calcCmax: temporaryTemperature];
  // detectDistance  = [self calcDetectDistanceAt: myCell]; 

  //
  // calculate our expected fitness here
  //
  presmoltFitnessHere = [self presmoltFitnessAt: myCell];
 
  if(destCellList == nil)
  {
      fprintf(stderr, "ERROR: Trout >>>> moveAsPresmolt >>>> destCellList is nil\n");
      fflush(0);
      exit(1);
  }

  //
  // destCellList must be empty
  // before it is populated.
  //
  [destCellList removeAll];
  
  //
  // Now, let the habitat space populate
  // the destCellList with myCells adjacent cells
  // and any other cells that are within
  // maxMoveDistance.
  //
  //fprintf(stdout, "Trout >>>> moveAsPresmolt >>>> maxMoveDistance = %f\n", maxMoveDistance);
   //fflush(0);
  //xprint(myCell);


  [myCell getNeighborsWithin: maxMoveDistance
                    withList: destCellList];

  destNdx = [destCellList listBegin: scratchZone];
  while (([destNdx getLoc] != End) && ((destCell = [destNdx next]) != nil))
  {
      //
      // SHUNT FOR DEPTH ... it's assumed fish won't jump onto shore
      //
      if([destCell getPolyCellDepth] <= 0.0)
      {
         continue;
      }

      presmoltFitnessAtDest = [self presmoltFitnessAt: destCell];

      if (presmoltFitnessAtDest >= bestPresmoltFitness) 
      {
	  bestPresmoltFitness = presmoltFitnessAtDest;
	  bestDest = destCell;
      }

   }  //while destNdx

   if(presmoltFitnessHere >= bestPresmoltFitness) 
   {
      //
      // Stay here 
      //
      bestDest = myCell;
      bestPresmoltFitness = presmoltFitnessHere;
   }

   if(bestDest == nil) 
   { 
      fprintf(stderr, "ERROR: Trout >>>> moveAsPresmolt >>>> bestDest is nil\n");
      fflush(0);
      exit(1);
   }

   // 
   //  Now, move -- No outmigration allowed for presmolts
   //

   [self moveToBestDest: bestDest];

   //
   // RESOURCE CLEANUP
   // 
   if(destNdx != nil) 
   {
     [destNdx drop];
   }


  //fprintf(stderr, "Trout >>>> moveAsPresmolt >>>> END >>>> presmoltFitnessAtDest = %f\n", presmoltFitnessAtDest);
  //fprintf(stderr, "Trout >>>> moveAsPresmolt >>>> END >>>> fish = %p\n", self);
  //fflush(0);

  return self;

} // moveAsPresmolt

//////////////////////////////////////////////////////////////////////
//
// moveAsSmolt
// modified from moveToMaximizeMaturity
//
//////////////////////////////////////////////////////////////////////
- moveAsSmolt
{
  // id <ListIndex> destNdx;
  // FishCell *destCell=nil;
  FishCell *bestDest=nil;
  // double bestExpectedMaturity=0.0;
  // double expectedMaturityHere=0.0;
  // double expectedMaturityAtDest=0.0;

  // double outMigFuncValue = [juveOutMigLogistic evaluateFor: fishLength];

  //fprintf(stdout, "Trout >>>> moveAsSmolt >>>> BEGIN >>>> fish = %p\n", self);
  //fprintf(stdout, "Trout >>>> moveAsSmolt >>>> outMigFuncValue = %f\n", outMigFuncValue);
  //fflush(0);
  //exit(0);

  if(myCell == nil) 
  {
    fprintf(stderr, "WARNING: Trout >>>> moveAsSmolt >>>> Fish 0x%p has no Cell context.\n", self);
    fflush(0);
    return self;
  }

  
       //
       // Find a cell in the downstreamLinksToUS 
       //
       
       //fprintf(stdout, "Trout >>>> moveAsSmolt >>>> moving to downstream reach >>>> BEGIN\n");
       //fflush(0);

       id <List> habDownstreamLinksToUS =  [reach getHabDownstreamLinksToUS];
       if([habDownstreamLinksToUS getCount] > 0)
       {
           id aReach = nil;
           id <ListIndex> reachNdx = [habDownstreamLinksToUS listBegin: scratchZone];
           id <List> oReachPotentialCells = [List create: scratchZone];
           int numOKCells = 0;
           while(([reachNdx getLoc] != End) && ((aReach = [reachNdx next]) != nil))
           {
   // Starting in V. 1.5, select among all DS cells that are not dry and have
   // velocity less than fish max swim speed.

                  id <List> cellList = [aReach getPolyCellList]; 
 
                  if([cellList getCount] > 0)
                  { 
                      id <ListIndex> clNdx = [cellList listBegin: scratchZone];
                      FishCell* fishCell = nil;
                 
                      while(([clNdx getLoc] != End) && ((fishCell = [clNdx next]) != nil))
                      {
    // Starting in V. 1.5, fish move down only into non-dry cells with vel < maxSwimSpeed
    // Note that maxSwimSpeed is not updated for different temperature in new reach
                          if([fishCell getPolyCellDepth] > 0.0 && [fishCell getPolyCellVelocity] < maxSwimSpeedForCell)
                          {
                              numOKCells++;
                              [oReachPotentialCells addLast: fishCell];
                          }
                       }
                       [clNdx drop];
                       clNdx = nil;
                  }
            }
            [reachNdx drop];

            if(numOKCells == 0)
            {
                 [self moveToBestDest: bestDest];
                  fprintf(stderr, "WARNING: Trout >>>> moveAsSmolt >>>>  habDownstreamLinksToUS none have good depth & vel >>>> juvenile staying in reach %s\n", [reach getReachName]);
                  fflush(0);
            }
            else if(numOKCells == 1)
            {
                 bestDest = [oReachPotentialCells getFirst];
            }
            else
            {
                   //
                   // randomly select one the cells meeting criteria
                   //
                   unsigned oReachCellChoice = [oReachCellChoiceDist getUnsignedWithMin: 0 withMax: (unsigned) (numOKCells - 1)]; 

                   bestDest = [oReachPotentialCells atOffset: oReachCellChoice];

            }
               // 
               // Now move to the downstream reach and repeat the move
               //
                  [self moveToBestDest: bestDest];
              //    [self moveToMaximizeExpectedMaturity];
			// Smolts move only one reach per day, so use presmolt method
			// to find a good cell.
                  [self moveAsPresmolt]; 
        
            [oReachPotentialCells removeAll];
            [oReachPotentialCells drop];
            oReachPotentialCells = nil;

//         fprintf(stdout, "Trout >>>> moveAsSmolt >>>> moving to downstream reach >>>> reach = %s\n", [reach getReachName]);
//         fprintf(stdout, "Trout >>>> moveAsSmolt >>>> moving to downstream [[myCell getReach] getReachName] %s\n", [[myCell getReach] getReachName]);
//         fprintf(stdout, "Trout >>>> moveAsSmolt >>>> moving to downstream [[bestDest getReach] getReachName] %s\n", [[bestDest getReach] getReachName]);
//         fprintf(stdout, "Trout >>>> moveAsSmolt >>>> moving to downstream reach >>>> END\n");
//         fflush(0);

         }

         else   // No downstream reach to move into, so migrate out
         {
               //
               // remove self from model
               // bestDest is needed in outmigrateFrom
               // so we can write output on movement from there.
               //
               [self outmigrateFrom: bestDest];
               //[bestDest removeFish: self]; 
         }



  //fprintf(stderr, "Trout >>>> moveAsSmolt >>>> END >>>> expectedMaturityAtDest = %f\n", expectedMaturityAtDest);
  //fprintf(stderr, "Trout >>>> moveAsSmolt >>>> END >>>> fish = %p\n", self);
  //fflush(0);

  return self;

} // moveAsSmolt

//////////////////////////////////////////////////////////////////////
//
// moveAsPrespawner
// modified from moveAsPresolt
//
//////////////////////////////////////////////////////////////////////
- moveAsPrespawner              // Stub for now
{
  id <ListIndex> destNdx;
  FishCell *destCell=nil;
  FishCell *bestDest=nil;
  double bestPrespawnerFitness=0.0;
  double prespawnerFitnessHere=0.0;
  double prespawnerFitnessAtDest=0.0;

  //double outMigFuncValue = [juveOutMigLogistic evaluateFor: fishLength];

  //fprintf(stdout, "Trout >>>> moveAsPrespawner >>>> BEGIN >>>> fish = %p\n", self);
  //fprintf(stdout, "Trout >>>> moveAsPrespawner >>>> outMigFuncValue = %f\n", outMigFuncValue);
  //fflush(0);
  //exit(0);

  if(myCell == nil) 
  {
    fprintf(stderr, "WARNING: Trout >>>> moveAsPrespawner >>>> Fish 0x%p has no Cell context.\n", self);
    fflush(0);
    return self;
  }

  //
  // Calculate the variables that depend only on the reach that a fish is in.
  //  (can't do this because cells may be in multiple reaches, with different 
  //  temperature and turbidity. Moved to prespawnerFitnessAt:
  // temporaryTemperature = [myCell getTemperature];
  // standardResp    = [self calcStandardRespirationAt: myCell];
  // cMax            = [self calcCmax: temporaryTemperature];
  // detectDistance  = [self calcDetectDistanceAt: myCell]; 

  //
  // calculate our expected fitness here
  //
  prespawnerFitnessHere = [self prespawnerFitnessAt: myCell];
 
  if(destCellList == nil)
  {
      fprintf(stderr, "ERROR: Trout >>>> moveAsPrespawner >>>> destCellList is nil\n");
      fflush(0);
      exit(1);
  }

  //
  // destCellList must be empty
  // before it is populated.
  //
  [destCellList removeAll];
  
  //
  // Now, let the habitat space populate
  // the destCellList with myCells adjacent cells
  // and any other cells that are within
  // maxMoveDistance.
  //
  //fprintf(stdout, "Trout >>>> moveAsPrespawner >>>> maxMoveDistance = %f\n", maxMoveDistance);
   //fflush(0);
  //xprint(myCell);


  [myCell getNeighborsWithin: maxMoveDistance
                    withList: destCellList];

  destNdx = [destCellList listBegin: scratchZone];
  while (([destNdx getLoc] != End) && ((destCell = [destNdx next]) != nil))
  {
      //
      // SHUNT FOR DEPTH ... it's assumed fish won't jump onto shore
      //
      if([destCell getPolyCellDepth] <= 0.0)
      {
         continue;
      }

      prespawnerFitnessAtDest = [self prespawnerFitnessAt: destCell];

      if (prespawnerFitnessAtDest >= bestPrespawnerFitness) 
      {
	  bestPrespawnerFitness = prespawnerFitnessAtDest;
	  bestDest = destCell;
      }

   }  //while destNdx

   if(prespawnerFitnessHere >= bestPrespawnerFitness) 
   {
      //
      // Stay here 
      //
      bestDest = myCell;
      bestPrespawnerFitness = prespawnerFitnessHere;
   }

   if(bestDest == nil) 
   { 
      fprintf(stderr, "ERROR: Trout >>>> moveAsPrespawner >>>> bestDest is nil\n");
      fflush(0);
      exit(1);
   }

   // 
   //  Now, move -- No outmigration allowed for prespawners
   //

   [self moveToBestDest: bestDest];

   //
   // RESOURCE CLEANUP
   // 
   if(destNdx != nil) 
   {
     [destNdx drop];
   }


  //fprintf(stderr, "Trout >>>> moveAsPrespawner >>>> END >>>> prespawnerFitnessAtDest = %f\n", prespawnerFitnessAtDest);
  //fprintf(stderr, "Trout >>>> moveAsPrespawner >>>> END >>>> fish = %p\n", self);
  //fflush(0);

  return self;

}  // moveAsPrespawner

/////////////////////////////////////////////////////////////////////////////////////////
//
// selectLifeHistory
// inSALMO-FA -- the fifth fish action 
//
// This action includes updating growth & survival memory,
// transition of presmolts to smolts,
// decision of juveniles of whether to become presmolts, and
// decision by juveniles whether to become prespawners. 
//
////////////////////////////////////////////////////////////////////////////////////////
- selectLifeHistory
{

	double meanLengthGrowth;   // In length, over memory period
	double meanSurvival; // over memory period
	double anadromyGrowth;   // In weight, over anadromy time horizon
	double residenceGrowth;   // In weight, over residence time horizon
	id aMemory;          // Did not work to declare as <MemoryElement>
	id <Averager> theSurvivalAverager; 
	double predictedLength, predictedWeight;
	double anadromyFitness, residenceFitness;
	int residenceTimeHorizon;
	time_t now;
	
	if(causeOfDeath != nil) // Skip this method if fish is dead or outmigrated
	{
		return self;
	}

	
	now = [self getCurrentTimeT];
	
	// First, take care of presmolts
	if(lifestageSymbol == [model getPresmoltLifestageSymbol])
	{
		if(now >= smoltTime)
		{
			lifestageSymbol = [model getSmoltLifestageSymbol];
		}
		if([model getWriteLifeHistoryDecisionReport]){
			[self printLHRptWithStartStage: [model getPresmoltLifestageSymbol]
				endStage:  lifestageSymbol
				memListLength: -99
				anadGrowth: -99.9
				resGrowth: -99.9
				meanSurvival: -99.9
				resTimeHorizon: -99
				anadFitness: -99.9
				resFitness: -99.9];
		}
		return self;
	}
	
	// Everything below here should be done only by juveniles, so if
	// you aren't juvenile then report and quit.
	if(lifestageSymbol != [model getJuvenileLifestageSymbol])
	{
		if([model getWriteLifeHistoryDecisionReport]){
			[self printLHRptWithStartStage: lifestageSymbol
				endStage:  lifestageSymbol
				memListLength: -99
				anadGrowth: -99.9
				resGrowth: -99.9
				meanSurvival: -99.9
				resTimeHorizon: -99
				anadFitness: -99.9
				resFitness: -99.9];
		}
	 return self;
	}
	 
	// Juveniles do not make life history decisions after their age in years
	// exceeds 2
	if(age >= 2)
	{
		if([model getWriteLifeHistoryDecisionReport]){
			[self printLHRptWithStartStage: [model getJuvenileLifestageSymbol]
				endStage:  lifestageSymbol
				memListLength: -99
				anadGrowth: -99.9
				resGrowth: -99.9
				meanSurvival: -99.9
				resTimeHorizon: -99
				anadFitness: -99.9
				resFitness: -99.9];
		}
		return self;
	}
	
	// fprintf(stdout, "OMykiss >>>> selectLifeHistory >>>> Before create memory\n");
	// fflush(0);

	// Update memory list with today's length & survival
	aMemory = [MemoryElement createBegin: [model getModelZone]
			withLength: fishLength
			andSurvival: nonStarvSurvival];
	aMemory = [aMemory createEnd];

	// fprintf(stdout, "OMykiss >>>> After new memory; today's length: %f, today's survival: %f\n", 
	// [aMemory getLengthValue], [aMemory getSurvivalValue]);
	
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
	// Length of memoryList should equal age in days up to fishMemoryListLength
	if([memoryList getCount] < (fishParams->fishMemoryListLength))
	{
		if([model getWriteLifeHistoryDecisionReport]){
			[self printLHRptWithStartStage: [model getJuvenileLifestageSymbol]
				endStage:  lifestageSymbol
				memListLength: [memoryList getCount]
				anadGrowth: -99.9
				resGrowth: -99.9
				meanSurvival: -99.9
				resTimeHorizon: -99
				anadFitness: -99.9
				resFitness: -99.9];
		}
		return self;
	}

	// Now update means over memory
	// First create the averager if it doesn't exist.

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

	// Update averager and get means.
	// Mean growth is calculated from newest, oldest length value
	meanLengthGrowth = ([[memoryList getFirst] getLengthValue] - [[memoryList getLast] getLengthValue]) / ([memoryList getCount] - 1);
	
	[theSurvivalAverager setCollection: memoryList];
	[theSurvivalAverager update];
	meanSurvival = [theSurvivalAverager getAverage];

	// fprintf(stdout, "OMykiss >>>> After update; Memory length: %d, meanLengthGrowth: %f, meanSurvival: %f\n", 
	// [memoryList getCount], meanLengthGrowth, meanSurvival);

	//
	// Juvenile decides to become presmolt if its anadromy fitness
	// exceeds residence fitness
	//
	// First, calculate residence time horizon
	//
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
	
	// Estimate weight growth rate from length growth rate,
	// assuming condition is 1.0 if length growth is positive.
	// This depends on time horizon.
	if(meanLengthGrowth == 0.0) 
	{
		anadromyGrowth = 0.0;
		residenceGrowth = 0.0;
	}
	else
	{
		// First, anadromy
		predictedLength = fishLength + (meanLengthGrowth * fishParams->fishSmoltDelay);
		predictedWeight = fishParams->fishWeightParamA * (pow(predictedLength,fishParams->fishWeightParamB));
		anadromyGrowth = (predictedWeight - fishWeight) / fishParams->fishSmoltDelay;
		
		// Now residency
		predictedLength = fishLength + (meanLengthGrowth * residenceTimeHorizon);
		predictedWeight = fishParams->fishWeightParamA * (pow(predictedLength,fishParams->fishWeightParamB));
		residenceGrowth = (predictedWeight - fishWeight) / residenceTimeHorizon;
	}
	
	anadromyFitness = [self anadromyFitnessWithGrowth: anadromyGrowth
						andSurvival: meanSurvival
						andTimeHorizon: fishParams->fishSmoltDelay];

	residenceFitness = [self residenceFitnessWithGrowth: residenceGrowth
						andSurvival: meanSurvival
						andTimeHorizon: residenceTimeHorizon];
	
	if(anadromyFitness > residenceFitness)
	{
		lifestageSymbol = [model getPresmoltLifestageSymbol];
		smoltTime = now + (time_t) (fishParams->fishSmoltDelay * 86400); // convert days to seconds for time_t
		if([model getWriteLifeHistoryDecisionReport]){
			[self printLHRptWithStartStage: [model getJuvenileLifestageSymbol]
				endStage:  lifestageSymbol
				memListLength: [memoryList getCount]
				anadGrowth: anadromyGrowth
				resGrowth: residenceGrowth
				meanSurvival: meanSurvival
				resTimeHorizon: residenceTimeHorizon
				anadFitness: anadromyFitness
				resFitness: residenceFitness];
		}
		return self;
	}
	
	// Finally, if fish is still a juvenile when it is time to
	// commit to maturing at age 2, then switch it to prespawner.
	if((age == 1) && ([timeManager getNumberOfDaysBetween: now
		and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]]
			<= fishParams->fishMaturityDecisionInterval))
	{
		lifestageSymbol = [model getPrespawnLifestageSymbol];
	}

	if([model getWriteLifeHistoryDecisionReport]){
		[self printLHRptWithStartStage: [model getJuvenileLifestageSymbol]
			endStage:  lifestageSymbol
			memListLength: [memoryList getCount]
			anadGrowth: anadromyGrowth
			resGrowth: residenceGrowth
			meanSurvival: meanSurvival
			resTimeHorizon: residenceTimeHorizon
			anadFitness: anadromyFitness
			resFitness: residenceFitness];
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

	//fprintf(stdout, "OMykiss anadromyFitnessWithGrowth nonStarv: %f starv: %f ocean: %f offspring: %f\n", nonStarveSurvival, starvSurvival, oceanSurvival, expectedOffspring);
	
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

	//fprintf(stdout, "OMykiss residenceFitnessWithGrowth timeHor: %d nonStarv: %f starv: %f offspring: %f\n", someDays, nonStarveSurvival, starvSurvival, expectedOffspring);
	
	return nonStarveSurvival * starvSurvival * expectedOffspring;
}

////////////////////////////////////////////////
//
// presmoltFitnessAt
// modified from expectedMaturityAt
//
////////////////////////////////////////////////
- (double) presmoltFitnessAt: (FishCell *) aCell 
{ 
  double growthForCell;
  // double nonStarvSurvivalForCell; 
  int T; // fitness horizon
  // double conditionAtTForCell; 
  // double fracMatureAtTForCell; 
  // double T;                    //fishFitnessHorizon
  // double Kt, KT, a, b;
  // double starvSurvival;
  double presmoltFitnessAtACell = 0.0;
  double totalNonStarvSurv = 0.0;
  
  time_t now;

  // Time horizon is number of days until smolting, always at least 1
  // When this method is used by a smolt, set time horizon to 1
  if(lifestageSymbol == [model getSmoltLifestageSymbol]) {T = 1;}
  else
  {
	  now = [self getCurrentTimeT];
	  if(now > smoltTime)
	  {
		 fprintf(stderr, "ERROR: OMkiss >>>> presmoltFitnessAt >>>> smoltTime is before now\n");
		 fflush(0);
		 exit(1);
	  }
	  
	  T = [timeManager getNumberOfDaysBetween: now and: smoltTime];
	  if(T < 1) {T = 1;}
  }

  if(aCell == nil)
  {
     fprintf(stderr, "ERROR: OMkiss >>>> presmoltFitnessAt >>>> aCell = nil\n");
     fflush(0);
     exit(1);
  }

  growthForCell = [self calcNetEnergyForCell: aCell] / (fishParams->fishEnergyDensity);
  maxSwimSpeedForCell = [self calcMaxSwimSpeedAt: aCell];
  feedTimeForCell = [self calcFeedTimeAt: aCell];
  depthLengthRatioForCell = [self calcDepthLengthRatioAt: aCell];
  
  // and these trout instance variables depend on reach and fish
  standardResp = [self calcStandardRespirationAt: aCell];
  cMax = [self calcCmax: [aCell getTemperature]];
  detectDistance = [self calcDetectDistanceAt: aCell]; 


  //
  // Now update the survival manager...
  //

  if(aCell == nil)
  {
      fprintf(stderr, "OMkiss >>>> presmoltFitnessAt >>>> aCell is nil\n");
      fprintf(stderr, "OMkiss >>>> presmoltFitnessAt >>>> isSpawner = %d\n", (int) isSpawner);
      fflush(0);
      exit(1);
  }

  [aCell updateFishSurvivalProbFor: self];

  totalNonStarvSurv = [aCell getTotalKnownNonStarvSurvivalProbFor: self];

  if(isnan(totalNonStarvSurv) || isinf(totalNonStarvSurv))
  {
     fprintf(stderr, "ERROR: OMkiss >>>> presmoltFitnessAt >>>> totalNonStarvSurv = %f\n", totalNonStarvSurv);
     fflush(0);
  }

  presmoltFitnessAtACell = [self anadromyFitnessWithGrowth: growthForCell
						andSurvival: totalNonStarvSurv
						andTimeHorizon: T];
						
  if(isnan(presmoltFitnessAtACell) || isinf(presmoltFitnessAtACell))
  {
     fprintf(stderr, "ERROR: OMkiss >>>> presmoltFitnessAt >>>> presmoltFitnessAtACell = %f\n", presmoltFitnessAtACell);
     fflush(0);
     exit(1);
  }

  if(presmoltFitnessAtACell < 0.0)
  {
     fprintf(stderr, "ERROR: OMkiss >>>> presmoltFitnessAt >>>> presmoltFitnessAtACell = %f is less than ZERO\n", presmoltFitnessAtACell);
     fflush(0);
     exit(1);
  }

  return presmoltFitnessAtACell;
}  // presmoltFitnessAt

////////////////////////////////////////////////
//
// prespawnerFitnessAt
// modified from presmoltFitnessAt
//
////////////////////////////////////////////////
- (double) prespawnerFitnessAt: (FishCell *) aCell 
{ 
  double growthForCell;
  int T; // fitness horizon
  double prespawnerFitnessAtACell = 0.0;
  double totalNonStarvSurv = 0.0;
  
  time_t now;

	// First, calculate residence time horizon
	//
    // Time horizon is number of days until spawning, always at least 1
	now = [self getCurrentTimeT];
	if(age == 0) // assume fish spawn at age 2
	{
		T = 365 + [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
	} // age == 0
	else if(age == 1) // assume fish spawn at age 2
	{
		if([timeManager isTimeT: now betweenMMDD: "1/1" 
			andMMDD: fishParams->fishSpawnStartDate])
		{
			T = 365 + [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
		}
		else
		{
			T = [timeManager getNumberOfDaysBetween: now
			and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
					givenThisTimeT: now]];
		}
		
	} // age == 1
	else // for 2 and older residents, assume fish spawn next opportunity
	{
		T = [timeManager getNumberOfDaysBetween: now
		and: [timeManager getTimeTForNextMMDD: fishParams->fishSpawnStartDate
				givenThisTimeT: now]];
	} // age > 1
	
	// Time horizon is always > 0
	if(T < 1) {T = 1;}

  if(aCell == nil)
  {
     fprintf(stderr, "ERROR: OMkiss >>>> prespawnerFitnessAt >>>> aCell = nil\n");
     fflush(0);
     exit(1);
  }

  growthForCell = [self calcNetEnergyForCell: aCell] / (fishParams->fishEnergyDensity);

  maxSwimSpeedForCell = [self calcMaxSwimSpeedAt: aCell];
  feedTimeForCell = [self calcFeedTimeAt: aCell];
  depthLengthRatioForCell = [self calcDepthLengthRatioAt: aCell];
  
  // and these trout instance variables depend on reach and fish
  standardResp = [self calcStandardRespirationAt: aCell];
  cMax = [self calcCmax: [aCell getTemperature]];
  detectDistance = [self calcDetectDistanceAt: aCell]; 


  //
  // Now update the survival manager...
  //

  if(aCell == nil)
  {
      fprintf(stderr, "OMkiss >>>> prespawnerFitnessAt >>>> aCell is nil\n");
      fprintf(stderr, "OMkiss >>>> prespawnerFitnessAt >>>> isSpawner = %d\n", (int) isSpawner);
      fflush(0);
      exit(1);
  }

  [aCell updateFishSurvivalProbFor: self];

  totalNonStarvSurv = [aCell getTotalKnownNonStarvSurvivalProbFor: self];

  if(isnan(totalNonStarvSurv) || isinf(totalNonStarvSurv))
  {
     fprintf(stderr, "ERROR: OMkiss >>>> prespawnerFitnessAt >>>> totalNonStarvSurv = %f\n", totalNonStarvSurv);
     fflush(0);
  }

  prespawnerFitnessAtACell = [self residenceFitnessWithGrowth: growthForCell
						andSurvival: totalNonStarvSurv
						andTimeHorizon: T];
						
  if(isnan(prespawnerFitnessAtACell) || isinf(prespawnerFitnessAtACell))
  {
     fprintf(stderr, "ERROR: OMkiss >>>> prespawnerFitnessAt >>>> prespawnerFitnessAtACell = %f\n", prespawnerFitnessAtACell);
     fflush(0);
     exit(1);
  }

  if(prespawnerFitnessAtACell < 0.0)
  {
     fprintf(stderr, "ERROR: OMkiss >>>> prespawnerFitnessAt >>>> prespawnerFitnessAtACell = %f is less than ZERO\n", prespawnerFitnessAtACell);
     fflush(0);
     exit(1);
  }

  return prespawnerFitnessAtACell;
}  // prespawnerFitnessAt


/////////////////////////////////////////////////
//
// printLifeHistoryReportFor
//
/////////////////////////////////////////////////
- printLHRptWithStartStage: (id <Symbol>) startLifestageSymbol
	endStage:  (id <Symbol>) endLifestageSymbol
	memListLength: (int) aMemoryLength
	anadGrowth: (double) anAnadGrowth
	resGrowth: (double) aResGrowth
	meanSurvival: (double) aSurvival
	resTimeHorizon: (int) aHorizon
	anadFitness: (double) anAFitness
	resFitness: (double) aRFitness
{
  FILE * lifeHistoryRptPtr=NULL;
  const char * lifeHistoryFileName = "LifeHistory_Out.csv";
  static BOOL lifeHistoryFirstTime = YES;
  char * fileMetaData;

  if(lifeHistoryFirstTime == YES){
      if((lifeHistoryRptPtr = fopen(lifeHistoryFileName,"w+")) == NULL){
          fprintf(stderr, "ERROR: OMykiss >>>> printLHRptWithStartStage >>>> Cannot open report file %s for writing", lifeHistoryFileName);
          fflush(0);
          exit(1);
      }
       fileMetaData = [BreakoutReporter reportFileMetaData: scratchZone];
       fprintf(lifeHistoryRptPtr,"\n%s\n",fileMetaData);
       [scratchZone free: fileMetaData];
      fprintf(lifeHistoryRptPtr,"%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
	  "Date",
	   "FishID",
	   "Species",
	   "Sex",
	   "Age",
	   "StartLifestage",
	   "EndLifestage",
	   "SmoltTime(formatted)",
	   "SmoltTime(unformatted)",
	   "MemoryLength",
	   "AnadGrowth",
	   "ResGrowth",
	   "MeanSurvival",
	   "Length",
	   "Weight",
	   "starvPa",
	   "starvPb",
	   "ResTimeHorizon",
	   "AnadFitness",
	   "ResidentFitness");
  }
  if(lifeHistoryFirstTime == NO){
	if((lifeHistoryRptPtr = fopen(lifeHistoryFileName,"a")) == NULL) 
	{
        fprintf(stderr, "ERROR: OMykiss >>>> printLHRptWithStartStage >>>> Cannot open report file %s for writing", lifeHistoryFileName);
	    fflush(0);
	    exit(1);
	}
  }

  fprintf(lifeHistoryRptPtr,"%s,%d,%s,%s,%d,%s,%s,%s,%d,%d,%f,%f,%f,%f,%f,%f,%f,%d,%f,%f\n",
		[timeManager getDateWithTimeT: [self getCurrentTimeT]],
		   fishID,
		   [species getName],
		   [sex getName],
		   age,
		   [startLifestageSymbol getName],
		   [endLifestageSymbol getName],
		   [timeManager getDateWithTimeT: smoltTime],
		   (int) smoltTime,
		   aMemoryLength,
		   anAnadGrowth,
		   aResGrowth,
		   aSurvival,
		   fishLength,
		   fishWeight,
		   starvPa,
		   starvPb,
		   aHorizon,
		   anAFitness,
		   aRFitness);

  //fflush(lifeHistoryRptPtr);
  fclose(lifeHistoryRptPtr);
  lifeHistoryFirstTime = NO;
  return self;
}


@end
