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