﻿CREATE PARTITION FUNCTION [fn_ProjectSegmentStatus_CustomerId](INT)
    AS RANGE
    FOR VALUES (5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120, 125);

