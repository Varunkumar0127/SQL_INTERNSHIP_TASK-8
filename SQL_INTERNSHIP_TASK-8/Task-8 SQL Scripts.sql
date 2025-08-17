DELIMITER $$

CREATE PROCEDURE sp_create_booking (
  IN p_GuestID INT,
  IN p_RoomID INT,
  IN p_CheckIn DATE,
  IN p_CheckOut DATE
)
BEGIN
  -- check if guest exists
  IF NOT EXISTS (SELECT 1 FROM guests WHERE GuestID = p_GuestID) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest does not exist';
  END IF;

  -- check if room exists
  IF NOT EXISTS (SELECT 1 FROM rooms WHERE RoomID = p_RoomID) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room does not exist';
  END IF;

  -- check if room is available
  IF EXISTS (SELECT 1 FROM bookings 
             WHERE RoomID = p_RoomID 
               AND (p_CheckIn BETWEEN CheckInDate AND CheckOutDate
                OR p_CheckOut BETWEEN CheckInDate AND CheckOutDate)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for given dates';
  END IF;

  -- insert booking
  INSERT INTO bookings (GuestID, RoomID, CheckInDate, CheckOutDate, Status)
  VALUES (p_GuestID, p_RoomID, p_CheckIn, p_CheckOut, 'Confirmed');
END $$

DELIMITER ;

CALL sp_create_booking(1, 2, '2025-08-20', '2025-08-25');


DELIMITER $$

CREATE FUNCTION fn_booking_amount(p_BookingID INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_room_price DECIMAL(10,2);
  DECLARE v_checkin DATE;
  DECLARE v_checkout DATE;
  DECLARE v_days INT;
  DECLARE v_amount DECIMAL(10,2);

  -- get booking info
  SELECT r.PricePerNight, b.CheckInDate, b.CheckOutDate
  INTO v_room_price, v_checkin, v_checkout
  FROM bookings b
  JOIN rooms r ON b.RoomID = r.RoomID
  WHERE b.BookingID = p_BookingID;

  -- handle missing booking
  IF v_checkin IS NULL OR v_checkout IS NULL THEN
    RETURN 0.00;
  END IF;

  -- calculate days stayed
  SET v_days = DATEDIFF(v_checkout, v_checkin);
  IF v_days < 1 THEN
    SET v_days = 1; -- minimum one day charge
  END IF;

  -- total amount
  SET v_amount = v_days * v_room_price;
  RETURN v_amount;
END $$

DELIMITER ;

SELECT fn_booking_amount(1) AS TotalAmount;

DELIMITER $$

CREATE PROCEDURE sp_guest_booking_count (
  IN p_GuestID INT,
  OUT p_Total INT
)
BEGIN
  SELECT COUNT(*) INTO p_Total
  FROM bookings
  WHERE GuestID = p_GuestID;
END $$

DELIMITER ; 

CALL sp_guest_booking_count(1, @total); SELECT @total AS TotalBookings;




