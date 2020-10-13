import logging
from datetime import timedelta

from core import Feed
from core.errors import ObservableValidationError
from core.observables import Ip


class AlienVaultIPReputation(Feed):
    default_values = {
        "frequency": timedelta(hours=4),
        "name": "AlienVaultIPReputation",
        "source": "http://reputation.alienvault.com/reputation.data",
        "description": "Reputation IP generated by Alienvault",
    }

    def update(self):
        for index, line in self.update_csv(
            delimiter="#",
            comment=None,
            header=None,
            names=[
                "IP",
                "number_1",
                "number_2",
                "Tag",
                "Country",
                "City",
                "Coord",
                "number_3",
            ],
        ):
            self.analyze(line)

    def analyze(self, item):

        try:
            context = dict(source=self.name)

            ip_str = item["IP"]
            category = item["Tag"]
            country = item["Country"]
            ip = None
            try:
                ip = Ip.get_or_create(value=ip_str)
            except ObservableValidationError as e:
                logging.error(e)
                return False

            ip.add_source(self.name)

            context["country"] = country
            context["threat"] = category

            ip.tag(category)
            ip.add_context(context)

        except Exception as e:
            logging.error("Error to process the item %s %s" % (item, e))
            return False
        return True
