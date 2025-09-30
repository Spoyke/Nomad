library ieee;
use ieee.std_logic_1164.all;

entity hmdi_controler is
    generic (
        h_res : natural := 720;
        v_res : natural := 480;
        h_sync : natural := 61;
        h_fp : natural := 58; 
        h_bp : natural := 18;
        v_sync : natural := 5;
        v_fp : natural := 30;
        v_bp : natural := 9;

    );
    port (
        i_clk : in std_logic;
        i_rst_n: in std_logic;

        o_hdmi_hs : out std_logic;
        o_hdmi_vs : out std_logic;
        o_hdmi_de : out std_logic;
        o_pixel_en : out std_logic;

        o_pixel_address : out std_logic_vector(18 downto 0);
        o_x_counter : out std_logic_vector(9 downto 0);
        o_y_counter : out std_logic_vector(9 downto 0);

    );
end entity;

architecture structural of hdmi_cotroler is 
signal s_x_counter : std_logic_vector (9 downto 0);
