create database StockApp;
go

use StockApp;
go

create table users 
(
	user_id int primary key identity,
	username nvarchar(100) unique not null,
	password nvarchar(200) not null,
	email nvarchar(255) unique not null,
	phone nvarchar(20) not null,
	full_name nvarchar(255),
	birthday date,
	country nvarchar(200)
);
go

-- 1 người dùng có thể đăng nhập nhiều thiết bị
CREATE TABLE user_devices
(
    id INT PRIMARY KEY IDENTITY,
    user_id INT NOT NULL,
    device_id NVARCHAR(255) NOT NULL, -- ID của thiết bị (VD: UUID, IMEI...)
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Tham chiếu đến bảng users
);
GO

--stock table (Bảng cổ phiếu)
create table stocks
(
	stock_id int primary key identity, -- ID cổ phiếu
	symbol nvarchar(10) unique not null, -- Mã cố phiếu (1-5 ký tự), (VD: Apple là AAPL, Facebook là FB, FPT, VNM...)
	company_name nvarchar(255) not null, --Tên công ty
	market_cap decimal(18, 2),-- Vốn hóa thị trường, 
	--(cách tính: market_cap = số lượng cổ phiếu lưu hành * giá cổ phiếu hiện tại)
	/*
		Ví dụ: 1 công ty có 100 triệu cổ phiếu lưu hành và giá cổ phiếu hiện tại là 50usd,
		thì market cap của công ty sẽ là 5 tỷ usd (100 triệu * 50)
	*/
	sector nvarchar(200), --Ngành
	industry nvarchar(200), -- Lĩnh vực
	sector_en nvarchar(200), --Ngành tiếng anh
	industry_en nvarchar(200), -- Lĩnh vực tiếng anh
	stock_type nvarchar(50),
	--Common stock (cổ phiếu thường), preferred stock (Cổ phiếu ưu đãi),ETF (Quỹ đầu tư chứng khoán)
	rank int default 0, -- thứ hạng trong danh sách top stocks
	-- đứng đầu là top 1, tiếp đến là 2, 3, 4, 5,...... 
	rank_source nvarchar(200), -- nguồn rank
	reason nvarchar(255) --Nguyên nhân khiến cổ phiếu được đưa vào danh sách top stocks
);
go

--Cần lưu dữ liệu theo thời gian thực
create table quotes
(
	quote_id int primary key identity,
	stock_id int foreign key references stocks(stock_id), -- Tham chiếu đến bảng stocks
	price decimal(18,2) not null, -- Giá cổ phiếu
	change decimal(18,2) not null, -- Biến động giá cổ phiếu so với ngày trước đó
	percent_change decimal(18,2) not null, -- Tỷ lệ biến động giá cổ phiếu so với ngày trước đó
	volume int not null, -- Khối lượng giao dịch trong ngày
	time_stamp datetime not null, -- Thời điểm cập nhật giá cổ phiếu
);
go

--Các chỉ số (index => indices)
create table market_indices
(
	index_id int primary key identity,
	name nvarchar(255) not null,
	symbol nvarchar(50) unique not null
);
go

-- market_indices - stocks => có quan hệ nhiều-nhiều (n - n)
-- index_constituents : danh sách các công ty được chọn để 
-- tính toán chỉ số của một chỉ số thị trường chứng khoán nhất định
-- association table
create table index_constituents
(
	index_id int foreign key references market_indices(index_id),
	stock_id int foreign key references stocks(stock_id)
);
go

/*
	Chứng khoán phái sinh (derivatives) là các công cụ tài chính có giá trị phụ thuộc vào giá trị 
	của một tài sản cơ sở (underlying asset) như cổ phiếu, trái phiếu, hàng hóa, hoặc chỉ số. 
	Chứng khoán phái sinh không có giá trị tự thân, mà giá trị của nó thay đổi dựa trên sự thay đổi giá trị 
	của tài sản cơ sở.
*/
create table derivatives
(
	derivative_id int primary key identity, -- ID của chứng khoán phái sinh
	name nvarchar(255) not null, -- Tên của chứng khoán phái sinh
	underlying_asset_id int foreign key references stocks(stock_id), --ID của tài sản cơ sở mà chứng khoán phái sinh dựa trên
	contract_size int, -- kích thước hợp đồng (số lượng tài sản cơ bản trong 1 hợp đồng phái sinh)
	-- contract size khác nhau cho từng sản phẩm tài chính
	-- ví dụ như trong thị trường forex , contract size được tính theo số lượng lot
	-- trong khi đó ở thị trường hàng hóa , contract size được tính theo khối lượng hoặc số lượng sản phẩm tài chính
	expiration_date date, -- Ngày hết hạn của hợp đồng phái sinh
	strike_price decimal(18, 4), -- giá thực hiện
	-- giá thực hiện (giá mà người mua chứng khoán phái sinh có quyền mua/bán tài sản cơ sở)
	-- strike price thường được đặt ở 1 mức giá gần bằng với giá thị trương của tài sản cơ sở
	-- để tăng khả năng tùy chọn sẽ được sử dụng
	last_price DECIMAL(18, 2) NOT NULL, -- Giá cuối cùng
    change DECIMAL(18, 2) NOT NULL, -- Mức thay đổi giá so với phiên trước đó.
    percent_change DECIMAL(18, 2) NOT NULL, -- Tỷ lệ phần trăm thay đổi
    open_price DECIMAL(18, 2) NOT NULL, -- Giá mở cửa trong phiên giao dịch.
    high_price DECIMAL(18, 2) NOT NULL, -- Giá cao nhất trong phiên giao dịch.
    low_price DECIMAL(18, 2) NOT NULL, -- Giá thấp nhất trong phiên giao dịch.
    volume INT NOT NULL, -- Khối lượng giao dịch trong phiên.
    open_interest INT NOT NULL, -- Lượng hợp đồng mở chưa được thanh toán
    time_stamp DATETIME NOT NULL -- Thời gian ghi nhận
);
go

--covered warrants được đảm bảo bởi 1 bên thứ 3
-- thường là 1 ngân hàng hoặc 1 công ty chuyên cung cấp các dịch vụ này
create table covered_warrants
(
	warrant_id int primary key identity, -- ID của chứng quyền có bảo đảm
	underlying_asset_id int foreign key references stocks(stock_id), --ID của tài sản cơ sở liên quan(tham chiếu đến bảng cổ phiếu)
	issue_date date, -- Ngày phát hành chứng quyền có bảo đảm
	expiration_date date, -- Ngày hết hạn của chứng quyền có bảo đảm
	strike_price decimal(18, 4),-- giá thực hiện (giá mà người mua chứng khoán phái sinh có quyền mua/bán tài sản cơ sở)
	warrant_type nvarchar(50), --Loại chứng quyền có bảo đảm (ví dụ: mua(Call) hoặc bán (Put))
);
go

/*
	ETF (Exchange-Traded Fund) là một quỹ đầu tư được niêm yết và giao dịch trên các sàn chứng khoán 
	giống như cổ phiếu. Quỹ ETF đầu tư vào một danh mục tài sản, chẳng hạn như cổ phiếu, trái phiếu hoặc 
	các tài sản khác, và mục tiêu của nó thường là theo dõi hoặc mô phỏng hiệu suất của một chỉ số tài chính cụ thể,
	chẳng hạn như S&P 500, VN30 hoặc một rổ hàng hóa (vàng, dầu mỏ,...).
*/
create table etfs
(
	etf_id int primary key identity,-- ID của quỹ đầu tư chứng khoán (ETF)
	name nvarchar(255) not null, --Tên của quỹ đầu tư chứng khoán (ETF)
	symbol nvarchar(50) unique not null, --Ký hiệu của quỹ đầu tư chứng khoán (ETF) trên thị trường
	management_company nvarchar(255), -- Tên công ty quản lý quỹ đầu tư chứng khoán (ETF)
	inception_date date, -- Ngày thành lập quỹ đầu tư chứng khoán (ETF)
);
go

--Quan hệ giữa etf và etf_quete là quan hệ 1-n (1 quỹ đầu tư có nhiều bản ghi quete trong cùng 1 ngày)
create table etf_quete
(
	quete_id int primary key identity,
	etf_id int foreign key references etfs(etf_id), -- ID của quỹ đầu tư chứng khoán (ETF)
	price decimal(18,2) not null, -- Giá của quỹ đầu tư chứng khoán (ETF)
	change DECIMAL(18, 2) NOT NULL, -- Biến động giá của quỹ đầu tư chứng khoán (ETF) so với ngày trước đó
    percent_change DECIMAL(18, 2) NOT NULL, -- Tỷ lệ Biến động giá của quỹ đầu tư chứng khoán (ETF) so với ngày trước đó
	total_volume int not null, -- Tổng khối lượng giao dịch trong ngày
	time_stamp datetime not null, --Thời điểm cập nhật giá của quỹ đầu tư chứng khoán (ETF)
);
go

/*
	"ETF holding" (cổ phiếu nắm giữ của quỹ ETF) đề cập đến các tài sản mà một quỹ hoán đổi danh mục (ETF - Exchange-Traded Fund) 
	đang nắm giữ. ETF là một loại quỹ đầu tư chứa nhiều tài sản khác nhau, như cổ phiếu, trái phiếu, hoặc hàng hóa, và cho phép 
	nhà đầu tư mua bán trên sàn chứng khoán giống như cổ phiếu thông thường.
*/
create table etf_holdings
(
	--Id của quỹ đầu tư chứng khoán(ETF) liên quan đến mã cổ phiếu được giữ (tham chiếu đến bảng etfs)
	etf_id int foreign key references etfs(etf_id),
	--Id của quỹ đầu tư chứng khoán(ETF) đang giữ (tham chiếu đến bảng stocks)
	stock_id int foreign key references stocks(stock_id),
	shares_held decimal(18, 4),
	--Số lượng cổ phiếu của mã cổ phiếu đó mà quỹ đầu tư chứng khoán đang nắm giữ
	weight decimal(18,4),
	--Trọng số của cổ phiếu đó trong tổng danh mục đầu tư của quỹ đầu tư chứng khoán (ETF) 
	--, thể hiện tỷ lệ phần trăm của cổ phiếu đó so với giá trị danh mục
);
go

-- watchlists bảng danh sách theo dõi mã cổ phiếu
-- N user theo dõi N stocks (nhiều user có thể theo dõi nhiều stock)
CREATE TABLE watchlists (
	user_id INT FOREIGN KEY REFERENCES users (user_id), -- ID người dùng 
	stock_id INT FOREIGN KEY REFERENCES stocks (stock_id) -- ID cổ phiếu
);
go


-- Orders table (Bảng đơn hàng /đặt lệnh)
/*
Market order: Lệnh mua/bán thực hiện ngay lập tức với giá thị trường hiện tại.
Trong trường hợp không có sẵn đủ số lượng cổ phiếu mà bạn yêu cầu,
thì lệnh sẽ được thực hiện với số lượng tối đa có thể đáp ứng được trên thị trường.

Limit order: Lệnh mua/bán với giá giới hạn. Bạn chỉ muốn mua/bán chứng khoán với giá mà bạn muốn, 
thay vì giá thị trường hiện tại. Lệnh mua sẽ được thực hiện với giá thấp hơn hoặc bằng giá giới hạn, 
còn lệnh bán sẽ được thực hiện với giá cao hơn hoặc bằng giá giới hạn.

Stop order: Lệnh mua/bán chỉ được thực hiện khi giá chứng khoán đạt đến mức giá xác định trước đó. 
Lệnh mua sẽ được thực hiện khi giá chứng khoán vượt qua giá stop,
còn lệnh bán sẽ được thực hiện khi giá chứng khoán giảm dưới mức giá stop. 
Lệnh stop order thường được sử dụng để giảm thiểu rủi ro khi giao dịch, 
đặc biệt là trong các thị trường dao động mạnh.
*/
CREATE TABLE orders (
	order_id INT PRIMARY KEY IDENTITY(1,1), -- ID đơn hàng / lệnh
	user_id INT FOREIGN KEY REFERENCES users (user_id), -- ID người dùng 
	stock_id INT FOREIGN KEY REFERENCES stocks (stock_id), --ID cổ phiếu 
	order_type NVARCHAR(20), -- Loại đơn hàng (ví dụ: market, limit, stop) 
	direction NVARCHAR(20), --Hướng (ví dụ: buy (mua), sell (bán))
	quantity INT, -- Số lượng
	price DECIMAL(18, 4), -- Giá 
	status NVARCHAR(20),--Trạng thái (ví dụ: pending, executed, canceled) Ngày đặt hàng
	order_date DATETIME -- ngày đặt mua/ đặt lệnh
);
go

-- Portfolios table (Bảng danh mục đầu tư)
CREATE TABLE portfolios (
	user_id INT FOREIGN KEY REFERENCES users (user_id), -- ID người dùng 
	stock_id INT FOREIGN KEY REFERENCES stocks (stock_id), -- ID cổ phiếu
	quantity INT, -- Số lượng
	purchase_price DECIMAL(18, 4), -- Giá mua
	purchase_date DATETIME --Ngày mua
);
go

/*
Thông báo:
order_executed: Thông báo khi một đơn hàng mua hoặc bán chứng khoán đã được thực hiện thành công hoặc thất bại. 

price_alert: Thông báo khi giá của một cổ phiếu đạt đến một ngưỡng giá mà người dùng đã thiết lập trước đó. 

news_event: Thông báo về các sự kiện, tin tức mới liên quan đến các cổ phiếu trong danh mục đầu tư của người dùng.
*/
CREATE TABLE notifications (
	notification_id INT PRIMARY KEY IDENTITY(1,1), --ID thông báo
	user_id INT FOREIGN KEY REFERENCES users (user_id),--ID người dùng
	notification_type NVARCHAR(50), -- Loại thông báo (ví dụ: order_executed, price_alert, news_event) 
	content TEXT NOT NULL,--Nội dung thông báo
	is_read BIT DEFAULT 8, -- Đánh dấu đã đọc hay chưa đọc (1: đã đọc, 0: chưa đọc)
	created_at DATETIME--Thời điểm tạo thông báo
);
go

-- bảng tài liệu 
--Bảng này dùng để quản lý các tài liệu giáo dục trong nhiều lĩnh vực khác nhau như đầu tư, quản lý rủi ro, và chiến lược giao dịch.
CREATE TABLE educational_resources (
	resource_id INT PRIMARY KEY IDENTITY(1,1), -- ID tài liệu
	title NVARCHAR(255) NOT NULL, -- Tiêu đề
	content TEXT NOT NULL, -- Nội dung
	category NVARCHAR(100), -- Danh mục (ví dụ: đầu tư, chiến lược giao dịch, quản lý rủi ro) 
	date_published DATETIME -- Ngày xuất bản
);
go

-- Linked bank accounts table (Bảng tài khoản ngân hàng tiên kết)
/*
Routing number (mã số định tuyến) Là một mã số được sử dụng để xác định một ngân hàng tại Hoa Kỳ.
Mã số này gồm 9 chữ số và thường được sử dụng để thực hiện các giao dịch tiên ngân hàng,
chẳng hạn như chuyển khoản ngân hàng hoặc thanh toán bằng séc. Mỗi ngân hàng sẽ có một mã số định tuyến riêng,
giúp cho việc xác định và phân toại các giao dịch được thực hiện giữa các ngân hàng trở nên dễ dàng hơn.
*/
CREATE TABLE linked_bank_accounts (
	account_id INT PRIMARY KEY IDENTITY(1,1), -- ID tài khoản
	user_id INT FOREIGN KEY REFERENCES users(user_id), -- ID người dùng
	bank_name NVARCHAR(255) NOT NULL,-- Tên ngân hàng
	account_number NVARCHAR(50) NOT NULL, -- Số tài khoản
	routing_humber NVARCHAR(50), -- Số định tuyến
	account_type NVARCHAR(50) -- Loặi tài khoản (ví dụ: checking, savings)
);
go
/*
Khi một order được tạo ra, các bảng sau sẽ bị thay đổi:

Bảng orders: Sẽ thêm một bản ghi mới đại diện cho đơn hàng mới được tạo ra.

Bảng portfoLios: Nếu đơn hàng là loại mua (buy), số lượng cổ phiếu tương ứng sẽ được thêm vào
danh mục đầu tư của người dùng;

nếu đơn hàng là loại bán (sell), số lượng cổ phiếu tương ứng sẽ bị trừ đi từ danh mục đầu tư của người dùng.

Bảng notifications: Một thông báo mới có thể được tạo ra để thông báo cho người dùng về việc
đơn hàng đã được thực hiện thành công hoặc thất bại.

Bảng transactions: Nếu đơn hàng Là Loại mua (buy),
một giao dịch mới sẽ được thêm vào bảng này để đại diện cho số tiền
được rút ra từ tài khoản ngân hàng của người dùng và chuyển đến sàn giao dịch;
nếu đơn hàng tà Loại bán (sell),
một giao dịch mới sẽ được thêm vào bảng này để đại diện cho số tiền được
chuyển từ sàn giao dịch đến tài khoản ngân hàng của người dùng.

*/

CREATE TABLE transactions (
	transaction_id INT PRIMARY KEY IDENTITY(1,1), -- ID giao dịch
	user_id INT FOREIGN KEY REFERENCES users(user_id), -- ID người dùng
	linked_account_id INT FOREIGN KEY REFERENCES linked_bank_accounts(account_id), -- ID tài khoản Liên kết
	transaction_type NVARCHAR(50), -- Loại giao dịch (ví dụ: deposit, withdrawal)
	amount DECIMAL(18, 2), -- Số tiền
	transaction_date DATETIME-- Ngày giao dịch
);
go

/*
	INSERT DATA FAKE
*/

INSERT INTO users (username, password, email, phone, full_name, birthday, country)
VALUES 
('john_doe', 'password123', 'john.doe@example.com', '1234567890', 'John Doe', '1990-05-15', 'USA'),
('jane_smith', 'password456', 'jane.smith@example.com', '0987654321', 'Jane Smith', '1985-07-22', 'UK'),
('peter_parker', 'spiderweb789', 'peter.parker@example.com', '1122334455', 'Peter Parker', '1995-12-10', 'USA'),
('bruce_wayne', 'darkknight123', 'bruce.wayne@example.com', '2233445566', 'Bruce Wayne', '1980-02-19', 'USA'),
('clark_kent', 'superman987', 'clark.kent@example.com', '3344556677', 'Clark Kent', '1988-11-05', 'Canada');

go

INSERT INTO user_devices (user_id, device_id)
VALUES 
(1, 'device-uuid-1234'),  -- John Doe's device
(1, 'device-imei-5678'),  -- Another device for John Doe
(2, 'device-uuid-9876'),  -- Jane Smith's device
(3, 'device-imei-5432'),  -- Peter Parker's device
(4, 'device-uuid-1122'),  -- Bruce Wayne's device
(4, 'device-imei-3344'),  -- Another device for Bruce Wayne
(5, 'device-uuid-9988');  -- Clark Kent's device
go

INSERT INTO stocks (symbol, company_name, market_cap, sector, industry, sector_en, industry_en, stock_type, rank, rank_source, reason)
VALUES 
('AAPL', 'Apple Inc.', 2500000000000, 'Công nghệ', 'Phần cứng máy tính', 'Technology', 'Computer Hardware', 'Common stock', 1, 'Forbes', 'Hiệu suất cao liên tục trong lĩnh vực công nghệ'),
('FB', 'Meta Platforms Inc.', 900000000000, 'Công nghệ', 'Mạng xã hội', 'Technology', 'Social Media', 'Common stock', 2, 'Bloomberg', 'Thành công trong quảng cáo trực tuyến và mở rộng metaverse'),
('VNM', 'Vinamilk', 100000000000, 'Hàng tiêu dùng', 'Sản xuất thực phẩm', 'Consumer Goods', 'Food Production', 'Common stock', 5, 'VnEconomy', 'Doanh số bán hàng cao trong thị trường quốc tế'),
('FPT', 'FPT Corporation', 300000000000, 'Công nghệ', 'Dịch vụ phần mềm', 'Technology', 'Software Services', 'Common stock', 3, 'Vietstock', 'Tăng trưởng doanh thu dịch vụ công nghệ thông tin'),
('VIC', 'Vingroup', 500000000000, 'Bất động sản', 'Phát triển dự án', 'Real Estate', 'Project Development', 'Common stock', 4, 'VietnamFinance', 'Phát triển mạnh trong lĩnh vực bất động sản và xe điện');
GO

INSERT INTO quotes (stock_id, price, change, percent_change, volume, time_stamp)
VALUES 
(1, 150.25, -1.75, -1.15, 35000000, '2024-10-17 09:30:00'),
(2, 325.50, 3.25, 1.01, 12000000, '2024-10-17 09:30:00'),
(3, 92.10, 0.50, 0.55, 5000000, '2024-10-17 09:30:00'),
(4, 65.75, -0.75, -1.13, 8000000, '2024-10-17 09:30:00'),
(5, 75.00, 1.00, 1.35, 10000000, '2024-10-17 09:30:00');
GO

-- Thêm dữ liệu cho các chỉ số thị trường chứng khoán
INSERT INTO market_indices (name, symbol)
VALUES 
('S&P 500', 'SPX'),
('NASDAQ 100', 'NDX'),
('Dow Jones Industrial Average', 'DJIA'),
('FTSE 100', 'FTSE'),
('VN-Index', 'VNI');
GO

-- Thêm dữ liệu cho các công ty vào các chỉ số
-- Cổ phiếu giả định có ID từ 1 đến 10 cho các công ty khác nhau

-- Cổ phiếu thuộc S&P 500
INSERT INTO index_constituents (index_id, stock_id)
VALUES 
(1, 1), -- Apple (SPX)
(1, 2), -- Microsoft (SPX)
(1, 3); -- Amazon (SPX)
GO

-- Cổ phiếu thuộc NASDAQ 100
INSERT INTO index_constituents (index_id, stock_id)
VALUES 
(2, 1), -- Apple (NDX)
(2, 2), -- Microsoft (NDX)
(2, 4); -- Facebook (NDX)
GO

-- Cổ phiếu thuộc Dow Jones Industrial Average
INSERT INTO index_constituents (index_id, stock_id)
VALUES 
(3, 1), -- Apple (DJIA)
(3, 5), -- Coca Cola (DJIA)
(3, 6); -- Boeing (DJIA)
GO

-- Cổ phiếu thuộc FTSE 100
INSERT INTO index_constituents (index_id, stock_id)
VALUES 
(4, 7), -- HSBC (FTSE)
(4, 8), -- BP (FTSE)
(4, 9); -- Unilever (FTSE)
GO

-- Cổ phiếu thuộc VN-Index
INSERT INTO index_constituents (index_id, stock_id)
VALUES 
(5, 10), -- Vingroup (VNI)
(5, 11), -- FPT (VNI)
(5, 12); -- VNM (VNI)
GO

-- Thêm dữ liệu cho các chứng khoán phái sinh
INSERT INTO derivatives (name, underlying_asset_id, contract_size, expiration_date, strike_price, last_price, change, percent_change, open_price, high_price, low_price, volume, open_interest, time_stamp)
VALUES 
('S&P 500 Futures', 1, 50, '2024-12-20', 4200.50, 4215.00, 10.00, 0.24, 4205.00, 4220.00, 4190.00, 1500, 3000, GETDATE()),
('NASDAQ 100 Options', 2, 100, '2024-11-15', 3400.75, 3410.00, -5.00, -0.15, 3415.00, 3425.00, 3400.00, 800, 2000, GETDATE()),
('Gold Futures', 3, 10, '2025-01-30', 1800.00, 1795.50, -3.00, -0.17, 1798.00, 1810.00, 1790.00, 600, 1500, GETDATE()),
('Crude Oil Futures', 4, 100, '2024-12-15', 70.50, 71.00, 1.00, 1.43, 69.50, 72.00, 68.00, 1000, 2500, GETDATE()),
('Euro FX Futures', 5, 125000, '2024-10-20', 1.1500, 1.1520, 0.0050, 0.44, 1.1480, 1.1550, 1.1450, 1200, 1800, GETDATE());
GO


-- Thêm dữ liệu cho các chứng quyền có bảo đảm
INSERT INTO covered_warrants (underlying_asset_id, issue_date, expiration_date, strike_price, warrant_type)
VALUES 
(1, '2024-01-01', '2025-01-01', 4200.00, 'Call'),  -- Chứng quyền mua S&P 500
(2, '2024-03-01', '2024-12-01', 3400.00, 'Put'),   -- Chứng quyền bán NASDAQ 100
(3, '2024-05-01', '2025-05-01', 1800.00, 'Call'),  -- Chứng quyền mua vàng
(4, '2024-02-01', '2024-11-01', 70.00, 'Put'),      -- Chứng quyền bán dầu thô
(5, '2024-04-01', '2025-04-01', 1.1400, 'Call');    -- Chứng quyền mua Euro FX
GO

-- Thêm dữ liệu cho các quỹ đầu tư chứng khoán (ETF)
INSERT INTO etfs (name, symbol, management_company, inception_date)
VALUES 
('SPDR S&P 500 ETF Trust', 'SPY', 'State Street Global Advisors', '1993-01-22'),
('iShares Russell 2000 ETF', 'IWM', 'BlackRock', '2000-05-22'),
('Invesco QQQ Trust', 'QQQ', 'Invesco', '1999-03-10'),
('Vanguard Total Stock Market ETF', 'VTI', 'Vanguard Group', '2001-05-24'),
('iShares MSCI Emerging Markets ETF', 'EEM', 'BlackRock', '2003-04-07');
GO

-- Thêm dữ liệu cho các giá quỹ đầu tư chứng khoán (ETF)
INSERT INTO etf_quete (etf_id, price, change, percent_change, total_volume, time_stamp)
VALUES 
(1, 420.50, 2.00, 0.48, 1500000, GETDATE()),
(2, 225.30, -1.50, -0.66, 800000, GETDATE()),
(3, 350.75, 3.50, 1.01, 1200000, GETDATE()),
(4, 200.10, 1.10, 0.55, 950000, GETDATE()),
(5, 40.00, -0.20, -0.50, 500000, GETDATE());
GO

-- Thêm dữ liệu cho các cổ phiếu nắm giữ của quỹ ETF
INSERT INTO etf_holdings (etf_id, stock_id, shares_held, weight)
VALUES 
(1, 1, 500000, 0.05),  -- 5% cổ phiếu A trong SPY
(1, 2, 600000, 0.07),  -- 7% cổ phiếu B trong SPY
(2, 3, 400000, 0.06),  -- 6% cổ phiếu C trong IWM
(3, 4, 300000, 0.08),  -- 8% cổ phiếu D trong QQQ
(4, 5, 700000, 0.10);  -- 10% cổ phiếu E trong VTI
GO

-- Thêm dữ liệu cho danh sách theo dõi cổ phiếu
INSERT INTO watchlists (user_id, stock_id)
VALUES 
(1, 1),  -- Người dùng 1 theo dõi cổ phiếu A
(1, 2),  -- Người dùng 1 theo dõi cổ phiếu B
(2, 2),  -- Người dùng 2 theo dõi cổ phiếu B
(2, 3),  -- Người dùng 2 theo dõi cổ phiếu C
(3, 1),  -- Người dùng 3 theo dõi cổ phiếu A
(3, 3),  -- Người dùng 3 theo dõi cổ phiếu C
(3, 4);  -- Người dùng 3 theo dõi cổ phiếu D
GO

-- Thêm dữ liệu cho đơn hàng
INSERT INTO orders (user_id, stock_id, order_type, direction, quantity, price, status, order_date)
VALUES 
(1, 1, 'market', 'buy', 100, 50.00, 'executed', GETDATE()),    -- Người dùng 1 đặt lệnh mua cổ phiếu A
(1, 2, 'limit', 'sell', 50, 52.00, 'pending', GETDATE()),      -- Người dùng 1 đặt lệnh bán cổ phiếu B
(2, 2, 'stop', 'buy', 200, 51.00, 'pending', GETDATE()),       -- Người dùng 2 đặt lệnh mua cổ phiếu B
(2, 3, 'market', 'sell', 150, 48.50, 'executed', GETDATE()),   -- Người dùng 2 đặt lệnh bán cổ phiếu C
(3, 1, 'limit', 'buy', 250, 49.00, 'pending', GETDATE()),      -- Người dùng 3 đặt lệnh mua cổ phiếu A
(3, 4, 'stop', 'sell', 100, 55.00, 'pending', GETDATE());      -- Người dùng 3 đặt lệnh bán cổ phiếu D
GO

-- Thêm dữ liệu cho danh mục đầu tư
INSERT INTO portfolios (user_id, stock_id, quantity, purchase_price, purchase_date)
VALUES 
(1, 1, 100, 48.00, '2024-01-15'),  -- Người dùng 1 sở hữu 100 cổ phiếu A
(1, 2, 50, 51.00, '2024-02-10'),   -- Người dùng 1 sở hữu 50 cổ phiếu B
(2, 2, 200, 50.50, '2024-03-05'),  -- Người dùng 2 sở hữu 200 cổ phiếu B
(2, 3, 150, 47.00, '2024-04-12'),  -- Người dùng 2 sở hữu 150 cổ phiếu C
(3, 1, 250, 49.50, '2024-05-20'),  -- Người dùng 3 sở hữu 250 cổ phiếu A
(3, 4, 100, 54.00, '2024-06-30');  -- Người dùng 3 sở hữu 100 cổ phiếu D
GO

-- Thêm dữ liệu cho thông báo
INSERT INTO notifications (user_id, notification_type, content, is_read, created_at)
VALUES 
(1, 'order_executed', 'Đơn hàng mua cổ phiếu A đã được thực hiện thành công.', 0, GETDATE()),
(1, 'price_alert', 'Cổ phiếu B đã đạt đến giá 52.00.', 0, GETDATE()),
(2, 'news_event', 'Công ty C công bố lợi nhuận quý 3 tăng trưởng 20%.', 0, GETDATE()),
(2, 'order_executed', 'Đơn hàng bán cổ phiếu C đã được thực hiện thành công.', 1, GETDATE()),
(3, 'price_alert', 'Cổ phiếu D đã giảm xuống dưới 45.00.', 0, GETDATE());
GO

-- Thêm dữ liệu cho tài liệu giáo dục
INSERT INTO educational_resources (title, content, category, date_published)
VALUES 
('Hướng dẫn đầu tư cổ phiếu cho người mới bắt đầu', 'Tài liệu này giúp người đọc hiểu về cách đầu tư cổ phiếu.', 'Đầu tư', GETDATE()),
('Quản lý rủi ro trong đầu tư', 'Các chiến lược để giảm thiểu rủi ro khi đầu tư.', 'Quản lý rủi ro', GETDATE()),
('Chiến lược giao dịch ngắn hạn', 'Hướng dẫn và các mẹo để thực hiện giao dịch ngắn hạn hiệu quả.', 'Chiến lược giao dịch', GETDATE()),
('Tổng quan về thị trường chứng khoán', 'Thông tin cơ bản về cách thức hoạt động của thị trường chứng khoán.', 'Đầu tư', GETDATE());
GO

-- Thêm dữ liệu cho tài khoản ngân hàng liên kết
INSERT INTO linked_bank_accounts (user_id, bank_name, account_number, routing_humber, account_type)
VALUES 
(1, 'Ngân hàng A', '123456789', '987654321', 'checking'),  -- Tài khoản người dùng 1
(1, 'Ngân hàng B', '987654321', '123456789', 'savings'),   -- Tài khoản người dùng 1
(2, 'Ngân hàng C', '456789123', '321654987', 'checking'),  -- Tài khoản người dùng 2
(3, 'Ngân hàng D', '654321789', '789123456', 'savings');    -- Tài khoản người dùng 3
GO

-- Thêm dữ liệu cho giao dịch
INSERT INTO transactions (user_id, linked_account_id, transaction_type, amount, transaction_date)
VALUES 
(1, 1, 'withdrawal', 50000.00, GETDATE()),  -- Người dùng 1 rút 50,000
(1, 2, 'deposit', 30000.00, GETDATE()),     -- Người dùng 1 gửi 30,000
(2, 3, 'withdrawal', 100000.00, GETDATE()), -- Người dùng 2 rút 100,000
(3, 4, 'deposit', 75000.00, GETDATE());     -- Người dùng 3 gửi 75,000
GO

/*
	SELECT TABLE (View)
*/

create view v_stock_index as
select 
	s.stock_id,s.symbol,s.company_name, s.market_cap,
	s.sector_en, s.sector, s.industry_en, s.industry,
	s.stock_type, i.index_id, 
	m.symbol as index_symbol,m.name as index_name
from stocks as s
inner join index_constituents as i
on s.stock_id = i.stock_id
inner join market_indices as m
on m.index_id = i.index_id;
go

select 
	v.index_symbol,
	v.index_name,
	v.symbol as stock_symbol,
	v.company_name
from v_stock_index as v
order by v.index_symbol;
go


select 
	v.index_symbol,
	v.index_name,
	count(distinct v.company_name) as total_companies
from v_stock_index as v
group by v.index_symbol, v.index_name
order by v.index_symbol;
go
