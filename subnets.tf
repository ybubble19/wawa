resource "aws_subnet" "public" {
  count                   = "${length(var.availability_zones)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.tags.environment}-public-subnet-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_subnet" "private" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.main.id}"


  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index + length(var.availability_zones))}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags = {
    "Name" = "${var.tags.environment}-private-subnet-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_eip" "nat" {
  count = "${length(var.availability_zones)}"
  vpc   = true
  tags = merge(map("Name", format("%s-eip", var.tags["environment"])), var.tags)
}

resource "aws_nat_gateway" "main" {
  count         = "${length(var.availability_zones)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"

  tags = {
    "Name" = "${var.tags.environment}-nat-${element(var.availability_zones, count.index)}"  
  }
}

