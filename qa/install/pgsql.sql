CREATE TABLE result
(
  questionid character varying(500) NOT NULL,
  form character varying(500) NOT NULL,
  date date NOT NULL,
  "location" character varying NOT NULL,
  answer character varying(1000),
  taker character varying(40) NOT NULL,
  CONSTRAINT rpk PRIMARY KEY (questionid, form, taker, date, location)
);
