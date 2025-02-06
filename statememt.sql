-- 1 -------
SELECT 
    c.Name AS CustomerName,
	CASE 
     WHEN c.IsCorporation =1 THEN 'YES'
     WHEN c.IsCorporation =0 THEN 'NO'
     ELSE 'NEITHER'
	END AS isCorporation,
	SUM(coalesce(fr.landingfee,0)) AS LandingFees,
    SUM(coalesce(f.flat_fee,0)) AS FuellingFees,
    SUM(coalesce(mpr.cost,0)) AS ServiceFees,
    SUM(coalesce(cl.cost,0)) AS CleaningFees,
    SUM(coalesce(
		Case 
            WHEN (pr.parking_duration < 30) 
			THEN pr.parking_duration * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
            ELSE 30 * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
				+(pr.parking_duration - 30) * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
		END,0)) AS ParkingFees
FROM 
    customer c
    JOIN aircraft a ON c.CustomerID = a.OwnerID
    JOIN flightrecord fr ON a.AircraftID = fr.AircraftID AND fr.ArrivalDate  BETWEEN '2024-02-01' AND '2024-02-29'
    JOIN fuelling f ON a.AircraftID = f.AircraftID AND f.date BETWEEN '2024-02-01' AND '2024-02-29'
    JOIN cleaning cl ON a.AircraftID = cl.AircraftID AND cl.date BETWEEN '2024-02-01' AND '2024-02-29'
    JOIN parkingreservation pr ON a.AircraftID = pr.aircraftID
    LEFT JOIN parkingslot ps ON pr.parkingID = ps.parkingid
    LEFT JOIN hangar h ON pr.parkingID = h.hangarid
    LEFT JOIN groundslot g ON pr.parkingID = g.groundID
    
    -- calculate all the service here
    JOIN maintenancerecord mr on a.AircraftID=mr.AircraftID
    JOIN maintainence_part_record mpr on mpr.maintainence_part_id = mr.maintainence_part_id
    
    
WHERE 

    c.CustomerID=9

GROUP BY
    c.Name, c.IsCorporation;
    
    
-- 2 -------
SELECT 
    p.Name AS PilotName,
    a.Type AS AircraftType,
    a.reg_number AS RegistrationNumber,
    COUNT(*) AS NumFlights
FROM
    pilot p
    JOIN flightrecord fr ON p.PilotID = fr.PilotID
    JOIN aircraft a ON fr.AircraftID = a.AircraftID
WHERE
    p.isCustomer = 1
    AND fr.ArrivalDate BETWEEN '2024-02-01' AND '2024-02-29'
GROUP BY
    p.Name, a.Type, a.reg_number
ORDER BY 
    NumFlights DESC
LIMIT 1;


-- 3 -------
SELECT DISTINCT
    e.EmployeeID,
    e.Name,
    e.phone,
    'Service Personnel' AS Role 
FROM
    employee e
    JOIN team_members tm ON e.EmployeeID = tm.employeeid
    JOIN serviceteams st ON tm.teamid = st.TeamID
    JOIN maintainence_part_record mpr ON st.TeamID = mpr.teamid
    JOIN maintenancerecord mr ON mpr.maintainence_part_id = mr.maintainence_part_id
    LEFT JOIN aircraft a ON mr.AircraftID = a.AircraftID
    JOIN customer c ON a.OwnerID = c.CustomerID
WHERE

-- CUSTOMER ID RANGE : 3,5,7,9 WHO ARE corporation
    c.CustomerID = 9
    AND c.IsCorporation = 1
    
-- select the date range here
    AND mpr.maintainence_part_date BETWEEN '2023-01-01' AND '2024-02-29';
    
    
-- 4 -------
SELECT DISTINCT
    a.Type AS AircraftType,
    mpr.part_number AS PartNumber, 
    mpr.part_name AS PartName,
    mpr.work_desc AS Description
FROM
    employee e
    JOIN team_members tm ON e.EmployeeID = tm.employeeid
    JOIN serviceteams st ON tm.teamid = st.TeamID
    JOIN maintainence_part_record mpr ON st.TeamID = mpr.teamid
    JOIN maintenancerecord mr ON mpr.maintainence_part_id = mr.maintainence_part_id
    JOIN aircraft a ON mr.AircraftID = a.AircraftID
    JOIN customer c ON a.OwnerID = c.CustomerID
WHERE

-- CUSTOMER ID RANGE : 3,5,7,9 WHO ARE corporation --
    c.CustomerID = 9
    AND c.IsCorporation = 1
    
-- the data is limited, so select the range between Jan and Feb HERE - -
    AND mpr.maintainence_part_date BETWEEN '2024-01-01' AND '2024-02-29'
ORDER BY
    a.Type, mpr.part_name;
    
    
-- 5 -------
SELECT
    a.ModelNumber,
    a.Type,
    a.reg_number,
     -- here CALCULATE all the fees --
    SUM(coalesce(fr.landingfee,0)) AS LandingFees,
    SUM(coalesce(f.flat_fee,0)) AS FuellingFees,
    SUM(coalesce(mpr.cost,0)) AS ServiceFees,
    SUM(coalesce(cl.cost,0)) AS CleaningFees,
    SUM(coalesce((Case WHEN (pr.parking_duration < 30) 
			THEN pr.parking_duration * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
            WHEN (pr.parking_duration >= 30) 
			THEN 30 * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
				+(pr.parking_duration-30) * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
		END),0)) AS ParkingFees,
   
    SUM(coalesce(fr.landingfee,0))
    +SUM(coalesce(f.flat_fee,0))
    +SUM(coalesce(mpr.cost,0))
    +SUM(coalesce(cl.cost,0))
    +SUM(coalesce((Case WHEN (pr.parking_duration < 30) 
			THEN pr.parking_duration * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
            WHEN (pr.parking_duration >= 30) 
			THEN 30 * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
				+(pr.parking_duration-30) * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
		END),0)) AS RevenuePerAircraft
    
FROM
    aircraft a
    LEFT JOIN flightrecord fr ON a.AircraftID = fr.AircraftID AND fr.ArrivalDate BETWEEN '2024-02-01' AND '2024-02-29'
    LEFT JOIN fuelling f ON a.AircraftID = f.AircraftID AND f.Date BETWEEN '2024-02-01' AND '2024-02-29'
    LEFT JOIN cleaning cl ON a.AircraftID = cl.AircraftID AND cl.Date BETWEEN '2024-02-01' AND '2024-02-29'  
    LEFT JOIN parkingreservation pr ON a.AircraftID = pr.aircraftID AND pr.StartDate BETWEEN '2024-02-01' AND '2024-02-29'  
	LEFT JOIN parkingslot ps ON pr.parkingID = ps.parkingid
    LEFT JOIN hangar h ON pr.parkingID = h.hangarid
    LEFT JOIN groundslot g ON pr.parkingID = g.groundID

     -- calculate all the service here
    JOIN maintenancerecord mr on a.AircraftID=mr.AircraftID
    JOIN maintainence_part_record mpr on mpr.maintainence_part_id = mr.maintainence_part_id AND mpr.maintainence_part_date BETWEEN '2024-02-01' AND '2024-02-29' 
    
GROUP BY
    a.Type, a.ModelNumber, a.reg_number
    
ORDER BY
    RevenuePerAircraft DESC;
    
    
-- here select the total revenue for the whole airport --
SELECT 
    SUM(RevenuePerAircraft) AS TotalRevenue
FROM
    (SELECT
         SUM(coalesce(fr.landingfee,0))
		+SUM(coalesce(f.flat_fee,0))
		+SUM(coalesce(mpr.cost,0))
		+SUM(coalesce(cl.cost,0))
		+SUM(coalesce((Case WHEN (pr.parking_duration < 30) 
				THEN pr.parking_duration * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
				WHEN (pr.parking_duration >= 30) 
				THEN 30 * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
					+(pr.parking_duration-30) * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
			END),0)) AS RevenuePerAircraft
		
	FROM
		aircraft a
		LEFT JOIN flightrecord fr ON a.AircraftID = fr.AircraftID AND fr.ArrivalDate BETWEEN '2024-02-01' AND '2024-02-29'
		LEFT JOIN fuelling f ON a.AircraftID = f.AircraftID AND f.Date BETWEEN '2024-02-01' AND '2024-02-29'
		LEFT JOIN cleaning cl ON a.AircraftID = cl.AircraftID AND cl.Date BETWEEN '2024-02-01' AND '2024-02-29'  
		LEFT JOIN parkingreservation pr ON a.AircraftID = pr.aircraftID AND pr.StartDate BETWEEN '2024-02-01' AND '2024-02-29'  
		LEFT JOIN parkingslot ps ON pr.parkingID = ps.parkingid
		LEFT JOIN hangar h ON pr.parkingID = h.hangarid
		LEFT JOIN groundslot g ON pr.parkingID = g.groundID

		 -- calculate all the service here
		JOIN maintenancerecord mr on a.AircraftID=mr.AircraftID
		JOIN maintainence_part_record mpr on mpr.maintainence_part_id = mr.maintainence_part_id AND mpr.maintainence_part_date BETWEEN '2024-02-01' AND '2024-02-29' 
		GROUP BY
			a.AircraftID
    HAVING
       SUM(coalesce(fr.landingfee,0))
		+SUM(coalesce(f.flat_fee,0))
		+SUM(coalesce(mpr.cost,0))
		+SUM(coalesce(cl.cost,0))
		+SUM(coalesce((Case WHEN (pr.parking_duration < 30) 
				THEN pr.parking_duration * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
				WHEN (pr.parking_duration >= 30) 
				THEN 30 * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
					+(pr.parking_duration-30) * (CASE WHEN h.hangarid is not null THEN h.fee_per_day ELSE g.fee_per_day END)
			END),0)) > 0
        ) AS temp;