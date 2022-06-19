import FormError from "../FormError";
import PageLoader from "../PageLoader";
import CardOverlay from "./CardOverlay";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

const ReservationCard = ({ active, loading, vehicle, onReserve, reserveError }) => {
  if (!active) {
    return null;
  }
  if (loading) {
    return (
      <CardOverlay>
        <PageLoader relative />
      </CardOverlay>
    );
  }
  const { rate, vendorService } = vehicle;
  const { localizationVars: locVars } = rate;
  const handlePress = (e) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  return (
    <CardOverlay>
      <Card.Title className="mb-2 text-muted">{vendorService.name}</Card.Title>
      <Card.Text className="text-muted">
        {i18next.t("mobility:" + rate.localizationKey, {
          surchargeCents: locVars.surchargeCents * 0.01,
          unitCents: locVars.unitCents * 0.01,
        })}
      </Card.Text>
      <FormError error={reserveError} />
      <Button size="sm" variant="primary" className="w-100" onClick={handlePress}>
        {i18next.t("mobility:reserve_scooter")}
      </Button>
    </CardOverlay>
  );
};

export default ReservationCard;
