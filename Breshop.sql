CREATE TABLE client (
    id UUID PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    password VARCHAR(50) NOT NULL,
    name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    phone_number VARCHAR(50),
    wallet DECIMAL DEFAULT 0 CHECK (wallet >= 0),
    avg_rating DECIMAL CHECK (avg_rating > 0 AND avg_rating <= 5)
);

CREATE TABLE message (
    id UUID PRIMARY KEY,
    id_sender UUID NOT NULL REFERENCES client (id),
    id_receiver UUID NOT NULL REFERENCES client (id),
    datetime_sent TIMESTAMP NOT NULL,
    message VARCHAR(250) NOT NULL
);

CREATE TABLE image (
    id UUID PRIMARY KEY,
    id_message UUID NOT NULL REFERENCES message (id),
    image VARCHAR(100) NOT NULL
);

CREATE TABLE address (
    id UUID PRIMARY KEY,
    id_client UUID NOT NULL REFERENCES client (id),
    postal_code VARCHAR(8) NOT NULL,
    address1 VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    address3 VARCHAR(50),
    city VARCHAR(50) NOT NULL,
    state VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL
);

CREATE TABLE credit_card (
    id UUID NOT NULL,
    id_client UUID NOT NULL REFERENCES client (id),
    cc_number VARCHAR(16) NOT NULL,
    cvv VARCHAR(3) NOT NULL
);

CREATE TABLE item (
    id UUID PRIMARY KEY,
    id_seller UUID NOT NULL REFERENCES client (id),
    name VARCHAR(50) NOT NULL,
    description VARCHAR(100),
    price DECIMAL NOT NULL CHECK (price > 0),
    last_change TIMESTAMP NOT NULL DEFAULT NOW(),

    id_buyer UUID REFERENCES client (id),
    id_address UUID REFERENCES address (id)
);

CREATE TABLE seller_buyer_rating (
    id_seller UUID NOT NULL REFERENCES client (id),
    id_buyer UUID NOT NULL REFERENCES client (id),
    id_item UUID NOT NULL REFERENCES item (id),
    rating INT NOT NULL CHECK (rating > 0 AND rating <= 5),
    description VARCHAR(100),

    CONSTRAINT pk_seller_rating
        PRIMARY KEY (id_seller, id_buyer, id_item)
);

CREATE TABLE shopping_cart (
    id_buyer UUID NOT NULL REFERENCES client (id),
    id_item UUID NOT NULL REFERENCES item (id),

    CONSTRAINT pk_shopping_cart
      PRIMARY KEY (id_buyer, id_item)
);

CREATE OR REPLACE VIEW all_items AS
    SELECT i.name, i.description, i.price, c.name seller
    FROM item i, client c
    WHERE c.id = i.id_seller
    ORDER BY i.last_change DESC;

CREATE OR REPLACE FUNCTION all_items_from_seller(c_username VARCHAR)
RETURNS TABLE(name VARCHAR, description VARCHAR, price DECIMAL, seller VARCHAR) AS
$$
    SELECT i.name, i.description, i.price, c.name seller
    FROM item i, client c
    WHERE c.id = i.id_seller   
    AND c.username = c_username;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION all_addresses_from_client(c_username VARCHAR)
RETURNS TABLE(postal_code VARCHAR, address1 VARCHAR, address2 VARCHAR, address3 VARCHAR, city VARCHAR, state VARCHAR, country VARCHAR) AS
$$
    SELECT a.postal_code, a.address1, a.address2, 
      a.address3, a.city, a.state, a.country 
    FROM address a
    INNER JOIN client c ON c.id = a.id_client
    WHERE c.username = c_username;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_shopping_cart(c_username VARCHAR)
RETURNS TABLE(name VARCHAR, price DECIMAL) AS
$$
    SELECT i.name, i.price
    FROM item i
    INNER JOIN shopping_cart s ON s.id_item = i.id
    INNER JOIN client c ON c.id = s.id_buyer
    WHERE c.name = c_username;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_messages(id1 UUID, id2 UUID)
RETURNS TABLE(datetime_sent TIMESTAMP, message VARCHAR, name VARCHAR) AS
$$
  SELECT m.datetime_sent, c.name, m.message
  FROM message m, client c
  WHERE c.id = m.id_sender
  AND (c.id = id1
  OR c.id = id2)
  ORDER BY m.datetime_sent DESC;
$$ LANGUAGE SQL;
