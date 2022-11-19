import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import _ from "lodash";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";
import { Link, useNavigate } from "react-router-dom";

export default function OrderHistoryList() {
  const {
    state: orderHistory,
    loading,
    error,
  } = useAsyncFetch(api.getOrderHistory, {
    default: {},
    pickData: true,
  });
  const navigate = useNavigate();
  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading) {
    return <PageLoader />;
  }

  function handleNavigate(e, order) {
    const detailed = _.find(orderHistory.detailedOrders, { id: order.id });
    if (!detailed) {
      return;
    }
    e.preventDefault();
    navigate(`/order/${order.id}`, { state: { order: detailed } });
  }
  return (
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back="/food" />
        <h2>Order History</h2>
      </LayoutContainer>
      <LayoutContainer gutters>
        {!_.isEmpty(orderHistory?.items) && (
          <Stack gap={4} className="mt-4">
            {orderHistory?.items.map((o) => (
              <Order key={o.id} {...o} onNavigate={(e) => handleNavigate(e, o)} />
            ))}
          </Stack>
        )}
        {_.isEmpty(orderHistory?.items) && (
          <>
            <p>You haven&rsquo;t place any orders yet.</p>
            <p>
              <Link to="/food">
                Check out what&rsquo;s available. <i className="bi bi-arrow-right"></i>
              </Link>
            </p>
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function Order({ id, createdAt, total, image, serial, onNavigate }) {
  return (
    <Card>
      <Card.Body>
        <Stack direction="horizontal" gap={3}>
          <SumaImage image={image} width={80} h={80} className="border rounded" />
          <div>
            <Card.Link
              as={RLink}
              href={`/order/${id}`}
              className="h5"
              onClick={onNavigate}
            >
              Order {serial}
            </Card.Link>
            <Card.Text className="text-secondary mt-1">
              Placed {dayjs(createdAt).format("ll")}
              <br />
              <Money>{total}</Money>
            </Card.Text>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}
