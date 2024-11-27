library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity Opgave8 is
  Port (CLK100MHZ : in std_logic;
        SW : in std_logic;
        Cathodes : out std_logic_vector(6 downto 0);
        Anodes : out std_logic_vector(7 downto 0);
        PLup : in std_logic;
        PLdown : in std_logic;
        PRup : in std_logic;
        PRdown : in std_logic;
        VGA_R : out std_logic_vector(3 downto 0) := (others => '0');
        VGA_G : out std_logic_vector(3 downto 0) := "0000";
        VGA_B : out std_logic_vector(3 downto 0) := "0000";
        VGA_HS: out std_logic;                -- Hsync
        VGA_VS: out std_logic);               -- Vsync
end Opgave8;

architecture Behavioral of Opgave8 is

signal teller_CLK : integer range 0 to 1 := 0;
signal CLK25MHZ   : std_logic := '0';
signal HScount : integer range 0 to 799 := 0;
signal VScount : integer range 0 to 524 := 0;

-- posities
signal posx_pL : integer := 96+48+10+20;           -- standaar positie x van palletje 1
signal posy_pL : integer := 275;
signal posx_pR : integer := 754;
signal posy_pR : integer := 275;
signal posx_bal : integer := 463;                  
signal posy_bal : integer := 274;
signal dirx : std_logic := '0';      -- 0 = van L naar R (dus X+1 en Y wisselt af) || 1 = van R naar L (dus X-1 en Y wisselt af)
signal diry : std_logic := '0';      -- 0 = van boven naar beneden || 1 = van beneden naar boven

-- snelheden palletjes, balletjes
signal teller_palletjeL : integer range 0 to 50000 := 0;
signal teller_palletjeR : integer range 0 to 50000 := 0;
signal teller_bal : integer range 0 to 200000 := 0;

-- punten
signal CLK100Hz : std_logic := '0';
signal teller_punten : integer range 0 to 500000 := 0;
signal left : boolean := TRUE;
signal pointL : integer := 0;
signal pointR : integer := 0;

signal HSPulse : integer := 95;     -- hor sync pulse = 96
signal HBP : integer := 47;         -- hor back porche = 48
signal HVA : integer := 639;        -- hor visible area = 640
signal HFP : integer := 15;         -- hor front porch = 16
signal Htotaal : integer := 799;    -- 800

signal VSPulse : integer := 1;      -- ver sync pulse = 2
signal VBP : integer := 32;         -- ver back porche = 33
signal VVA : integer := 479;        -- ver visible area = 480
signal VFP : integer := 9;         -- ver front porch = 10
signal Vtotaal : integer := 524;    -- 525


type tSegm is array(0 to 15) of std_logic_vector(6 downto 0);     -- array = een lijst
  constant cSegm : tSegm := ("0000001",  -- 0
                             "1001111",  -- 1
                             "0010010",  -- 2
                             "0000110",  -- 3
                             "1001100",  -- 4
                             "0100100",  -- 5
                             "0100000",  -- 6
                             "0001111",  -- 7
                             "0000000",  -- 8
                             "0000100",  -- 9
                             "0001000",  -- A
                             "1100000",  -- b
                             "0110001",  -- C
                             "1000010",  -- d
                             "0110000",  -- E
                             "0111000"); -- F
                             

begin

clock_divider: process(CLK100MHZ)
    begin
    if rising_edge(CLK100MHZ) then
        if teller_CLK = 1 then
            CLK25MHZ <= not CLK25MHZ;
            teller_CLK <= 0;
        else
            teller_CLK <= teller_CLK + 1;
        end if;
    end if;
end process clock_divider;

hor_and_ver_counter: process(CLK25MHZ)
    begin
    if rising_edge(CLK25MHZ) then
        if  HScount = 799 then
            HScount <= 0;
            VScount <= VScount + 1;
        else
            HScount <= HScount + 1;
        end if;
        if  VScount = 524 then
            VScount <= 0;
        end if;
    end if;    
end process hor_and_ver_counter;

HS_pulse: process(HScount)
    begin
    if HScount < 96 then
        VGA_HS <= '0';
    else
        VGA_HS <= '1';
    end if;
end process HS_pulse;

VS_pulse: process(VScount)
    begin
    if VScount < 2 then
        VGA_VS <= '0';
    else
        VGA_VS <= '1';
    end if;
end process VS_pulse;

palletjeL: process(CLK25MHZ)
begin
    if rising_edge(CLK25MHZ) then
    -- dit is een teller die tot 50000 telt en elke keer als hij aan het einde is, zal het palletje bewegen
        if teller_palletjeL = 50000 then
            teller_palletjeL <= 0;
            if (PLup = '1' and PLdown = '1') or (PLup = '0' and PLdown = '0') then    -- aka wnr allebei (niet) zijn ingedrukt
                posy_pL <= posy_pL;                                                   -- het palletje zal stil blijven staan
            elsif PLup = '1' and PLdown = '0' then
                if posy_pL >= 104 then
                    posy_pL <= posy_pL - 1;
                else
                    posy_pL <= posy_pL;
                end if;
            else
                if posy_pL <= 445 then
                    posy_pL <= posy_pL + 1;
                else
                    posy_pL <= posy_pL;
                end if;
            end if;
        else
            teller_palletjeL <= teller_palletjeL + 1;
        end if;
    end if;
end process palletjeL;

palletjeR: process(CLK25MHZ)
begin
    if rising_edge(CLK25MHZ) then
    -- dit is een teller die tot 1000000 telt en elke keer als hij aan het einde is, zal het palletje bewegen
        if teller_palletjeR = 50000 then
            teller_palletjeR <= 0;
            if (PRup = '1' and PRdown = '1') or (PRup = '0' and PRdown = '0') then    -- aka wnr allebei (niet) zijn ingedrukt
                posy_pR <= posy_pR;                                                   -- het palletje zal stil blijven staan
            elsif PRup = '1' and PRdown = '0' then
                if posy_pR >= 104 then
                    posy_pR <= posy_pR - 1;
                else
                    posy_pR <= posy_pR;
                end if;
            else
                if posy_pR <= 445 then
                    posy_pR <= posy_pR + 1;
                else
                    posy_pR <= posy_pR;
                end if;
            end if;
        else
            teller_palletjeR <= teller_palletjeR + 1;
        end if;
    end if;
end process palletjeR;  

balletje: process(CLK25MHZ)
begin
    if rising_edge(CLK25MHZ) then
    if pointL = 10 or pointR = 10 then
        pointL <= 0;
        pointR <= 0;
    else
        if teller_bal = 200000 then
            teller_bal <= 0;
            -- richting bal
            if dirx = '0' then
                posx_bal <= posx_bal + 1;
            else
                posx_bal <= posx_bal - 1;
            end if;
            if diry = '0' then
                posy_bal <= posy_bal + 1;
            else
                posy_bal <= posy_bal - 1;   
            end if;
            if posy_bal >= 505 then                 -- als het de x border raakt beneden
                    diry <= '1';
                elsif posy_bal <= 45 then           -- als het de x border raakt boven
                    diry <= '0';
                elsif posx_bal < 154 then           -- als het de y border raakt links             DEAD
                    dirx <= '0';
                    posx_bal <= 463;                  
                    posy_bal <= 274;
                    pointR <= pointR + 1;
                elsif posx_bal > 774 then           -- als het de y border raakt rechts            DEAD
                    dirx <= '1';
                    posx_bal <= 463;                  
                    posy_bal <= 274;
                    pointL <= pointL + 1;
                elsif posx_bal = posx_pL + 15 and posy_bal >= posy_pL - 60 and posy_bal <= posy_pL + 60 then      -- als het het linkse palletje raakt                
                    dirx <= '0';
                elsif posx_bal = posx_pR - 15 and posy_bal >= posy_pR - 60 and posy_bal <= posy_pR + 60 then      -- als het het rechtste palletje balletje
                    dirx <= '1';
                end if;             
        else
            teller_bal <= teller_bal + 1;
        end if;
    end if;
    end if;
end process balletje;

scherm: process(HScount, VScount, HSPulse, HBP, Htotaal, HFP, HVA, VSPulse, VBP, Vtotaal, VFP, VVA, posx_pL, posy_pL, posx_pR, posy_pR, posx_bal, posy_bal)
    begin
    VGA_R <= "0000";
    VGA_G <= "0000";
    VGA_B <= "0000";
    -- border y as
    if (HScount > HSPulse + HBP and HScount < HSPulse + HBP + 10 ) or (HScount > Htotaal - HFP - 10 and HScount <= Htotaal - HFP) then
        VGA_R <= "1111";
        VGA_G <= "1100";
        VGA_B <= "1010";
    -- border x as
    elsif (VScount > VSPulse + VBP and VScount < VSPulse + VBP + 10) or (VScount > Vtotaal - VFP - 10 and VScount < Vtotaal - VFP) then
        VGA_R <= "1111";
        VGA_G <= "1100";
        VGA_B <= "1010";
    -- middellijn
    elsif HScount > HSPulse + HBP + ((HVA/2)-2) and HScount < HSPulse + HBP + ((HVA/2)+2) then
        VGA_R <= "1111";
        VGA_G <= "1111";
        VGA_B <= "1111";
    -- palletje links
    elsif HScount >= posx_pL and HScount < posx_pL + 15 and VScount >= -60 + posy_pL and VScount < posy_pL + 60 then
        VGA_R <= "1101";
        VGA_G <= "1010";
        VGA_B <= "1010";
    -- palletje rechts
    elsif HScount >= posx_pR - 15 and HScount < posx_pR and VScount >= -60 + posy_pR and VScount < posy_pR + 60 then
        VGA_R <= "0000";
        VGA_G <= "1100";
        VGA_B <= "1110";
    -- balletje
    elsif HScount >= posx_bal - 3 and HScount < posx_bal + 3 and VScount >= posy_bal - 3 and VScount < posy_bal + 3 then
        VGA_R <= "1111";
        VGA_G <= "1111";
        VGA_B <= "1111";
    else
        VGA_R <= "0000";
        VGA_G <= "0000";
        VGA_B <= "0000";    
    end if;
end process scherm;

puntenklok: process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        if teller_punten = 499999 then
            CLK100Hz <= not CLK100Hz;
            teller_punten <= 0;
        else
            teller_punten <= teller_punten + 1;
        end if;
    end if;
end process puntenklok;

punten: process(CLK100Hz)
begin
    if rising_edge(CLK100Hz) then
        if left then
            left <= FALSE;
            Anodes <= "01111111";
            Cathodes <= cSegm(PointL);
        else
            left <= TRUE;
            Anodes <= "11111110";
            Cathodes <= cSegm(pointR);
        end if;
    end if;
end process punten;

end Behavioral;