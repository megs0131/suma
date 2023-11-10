import CartIcon from "./CartIcon";
import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function FoodNav({ offeringId, startElement, cart }) {
  if (startElement) {
    return (
      <Container className="hstack gap-3 border-0 py-2 px-4">
        {startElement && startElement}
        <div className="ms-auto py-1">
          <Button
            href={`/cart/${offeringId}`}
            variant={clsx(cart.items?.length > 0 ? "success" : "primary")}
            className="ms-auto py-1"
            as={RLink}
          >
            <CartIcon cart={cart} className="d-flex flex-row" />
          </Button>
        </div>
      </Container>
    );
  }
  return (
    <Button
      href={`/cart/${offeringId}`}
      variant="success"
      className="py-1 mt-2"
      as={RLink}
    >
      <CartIcon cart={cart} />
    </Button>
  );
}
