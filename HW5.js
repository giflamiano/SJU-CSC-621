/* 
    DB HW 5 
    Fall 2024
    Giannina Flamiano    
*/

// 1) Over how many years was the unemployment data collected?
db.unemployment.aggregate([
    { 
        $group: { _id: "$Year" } 
    },  
    { 
        $count: "totalYears" 
    }       
])
  

// 2) How many states were reported on in this dataset?
db.unemployment.aggregate([
    {
        $group: { _id: "$State" }
    },
    {
        $count: "totalStates"
    }
])


// 3) What does this query compute? db.unemployment.find({Rate : {$lt: 1.0}}).count()
db.unemployment.find({Rate : {$lt: 1.0}}).count()

// 4) Find all counties with unemployment rate higher than 10%
db.unemployment.aggregate([
    {
        $match: { Rate: { $gt:10 } }
    }, 
    {
        $group: { _id: "$County" }
    }
])

// 5) Calculate the average unemployment rate across all states.
db.unemployment.aggregate([
    {
      $project: {
        Rate: { $ifNull: ["$Rate", 0] }  
      }
    },
    {
      $group: {
        _id: 0,
        averageRate: { $avg: "$Rate" }
      }
    }
])

// 6) Find all counties with an unemployment rate between 5% and 8%.
db.unemployment.aggregate([
    {
        $match: {Rate: {$gt:5, $lt:8}}
    },
    {
        $group: { _id: "$County" }
    }
])

// 7) Find the state with the highest unemployment rate. Hint. Use { $limit: 1 }
db.unemployment.aggregate([
    {
        $sort: {Rate: -1}
    }, 
    {
        $limit: 1
    },
    {
        $group: { _id: "$State" }
    }
])

// 8) Count how many counties have an unemployment rate above 5%.
db.unemployment.aggregate([
    {   
        $match: { Rate: { $gt:5 } }
    }, 
    {
        $group: { _id: "$County" }
    },
    {
        $count: "countyCount"
    }
])

// 9) Calculate the average unemployment rate per state by year.
db.unemployment.aggregate([
    { 
      $group: { 
        _id: { 
            State: "$State", 
            Year: "$Year" 
        }, 
        avgRate: { $avg: "$Rate" }              
      } 
    },
    { 
      $project: { 
        _id: 0,                               
        State: "$_id.State",                   
        Year: "$_id.Year",                    
        avgRate: 1
      } 
    },
    { 
      $sort: { State: 1, Year: 1 } 
    }
])
  

// 10) (Extra Credit) For each state, calculate the total unemployment rate across all counties (sum of all county rates).
db.unemployment.aggregate([
    {
        $group: {
            _id: "$State",
            totalUnemploymentRate: { 
                $sum: { 
                    $divide: ["$Rate", 100] 
                } 
            }
        }
    },
    {
        $project: {
            _id: 0,                         
            State: "$_id",     
            totalUnemploymentRate: 1
        }
    }
])


// The code above returns documents that have a rate in the that is greater than 100%
// To fix this, the below code calculates the average unemployment rate per state across all counties
db.unemployment.aggregate([
    {
        $group: {
            _id: "$State",
            totalRate: { 
                $sum: { 
                    $divide: ["$Rate", 100] 
                } 
            },
            countyCount: { $sum: 1 }
        }
    },
    {
        $project: {
            _id: 0,
            State: "$_id",
            averageRate: { 
                $multiply: [{ 
                    $divide: ["$totalRate", "$countyCount"] 
                }, 100] } // normalize
        }
    }
])

  
// 11) (Extra Credit) The same as Query 10 but for states with data from 2015 onward
db.unemployment.aggregate([
    { 
        $match: { Year: { $gte: 2015 } }
    },
    {
        $group: {
            _id: "$State",
            totalUnemploymentRate: { 
                $sum: { 
                    $divide: ["$Rate", 100] 
                } 
            }
        }
    },
    {
        $project: {
            _id: 0,                         
            State: "$_id",     
            totalUnemploymentRate: 1
        }
    }
])

// The code above returns documents that have a rate greater than 100%
// To fix this, the below code calculates the average unemployment rate per state across all counties
db.unemployment.aggregate([
    { 
        $match: { Year: { $gte: 2015 } }
    },
    {
        $group: {
            _id: "$State",
            totalRate: { 
                $sum: { 
                    $divide: ["$Rate", 100] 
                } 
            },
            countyCount: { $sum: 1 } 
        }
    },
    {
        $project: {
            _id: 0,
            State: "$_id",
            averageRate: { 
                $multiply: [{ 
                    $divide: ["$totalRate", "$countyCount"] 
                }, 100] } // normalize
        }
    }
])
  